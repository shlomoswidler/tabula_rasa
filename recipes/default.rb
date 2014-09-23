# Prepare the platform
include_recipe "install_chef_client"

# Get the cookbooks
cookbook_dest = node[:tabula_rasa][:home_dir] + '/cookbooks'
## prepare the destination directory
directory node[:tabula_rasa][:home_dir] do
  recursive true
  action :create
  user node[:opsworks_custom_cookbooks][:user]
  group node[:opsworks_custom_cookbooks][:group]
  mode 00750
end

## From opsworks-cookbooks/opsworks_custom_cookbooks/recipes/checkout.rb
case node[:opsworks_custom_cookbooks][:scm][:type]
when 'git'
  git "Download Tabula-Rasa Cookbooks" do
    enable_submodules node[:opsworks_custom_cookbooks][:enable_submodules]
    depth nil

    user node[:opsworks_custom_cookbooks][:user]
    group node[:opsworks_custom_cookbooks][:group]
    action :checkout
    destination cookbook_dest
    repository node[:opsworks_custom_cookbooks][:scm][:repository]
    revision node[:opsworks_custom_cookbooks][:scm][:revision]
    retries 2
    not_if do
      node[:opsworks_custom_cookbooks][:scm][:repository].blank? || ::File.directory?(cookbook_dest)
    end
  end
when 'svn'
  subversion "Download Tabula-Rasa Cookbooks" do
    svn_username node[:opsworks_custom_cookbooks][:scm][:user]
    svn_password node[:opsworks_custom_cookbooks][:scm][:password]

    user node[:opsworks_custom_cookbooks][:user]
    group node[:opsworks_custom_cookbooks][:group]
    action :checkout
    destination cookbook_dest
    repository node[:opsworks_custom_cookbooks][:scm][:repository]
    revision node[:opsworks_custom_cookbooks][:scm][:revision]
    retries 2
    not_if do
      node[:opsworks_custom_cookbooks][:scm][:repository].blank? || ::File.directory?(cookbook_dest)
    end
  end
else
  raise "unsupported SCM type #{node[:opsworks_custom_cookbooks][:scm][:type].inspect}"
end

ruby_block 'Move single tabula-rasa cookbook contents into appropriate subdirectory' do
  block do
    cookbook_name = File.readlines(File.join(cookbook_dest, 'metadata.rb')).detect{|line| line.match(/^\s*name\s+\S+$/)}[/name\s+['"]([^'"]+)['"]/, 1]
    cookbook_path = File.join(cookbook_dest, cookbook_name)
    Chef::Log.info "Single cookbook detected, moving into subdirectory '#{cookbook_path}'"
    FileUtils.mkdir(cookbook_path)
    Dir.glob(File.join(cookbook_dest, '*'), File::FNM_DOTMATCH).each do |cookbook_content|
      FileUtils.mv(cookbook_content, cookbook_path, :force => true)
    end
  end

  only_if do
    ::File.exists?(metadata = File.join(cookbook_dest, 'metadata.rb')) && File.read(metadata).match(/^\s*name\s+\S+$/)
  end
end

## TODO: Will this work?? Probably not.
#include_recipe "opsworks_custom_cookbooks::berkshelf"

execute "ensure correct permissions of tabula-rasa cookbooks" do
  command "chmod -R go-rwx #{cookbook_dest}"
  only_if do
    ::File.exists?(cookbook_dest)
  end
end

# Prepare the config for the chef client run
## Recipes are specified in the Stack Custom JSON in node[:tabula_rasa][:recipes]
## as a map for the current lifecycle event:
## { "tabula_rasa" : { 
##     "recipes" : { 
##       "configure": [ "mysql::client" ] 
##     }
##   }
## }


# Run the chef client
