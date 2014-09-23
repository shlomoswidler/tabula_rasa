## Recipes are specified in the Stack Custom JSON in node[:tabula_rasa][:recipes]
## as a map for the current lifecycle event:
## { "tabula_rasa" : { 
##     "recipes" : { 
##       "configure": [ "mysql::client" ] 
##     }
##   }
## }
activity = node[:opsworks][:activity]
recipes = node[:tabula_rasa][:recipes][activity]
return if recipes.nil? || recipes.size == 0

# Create directories
directory node[:tabula_rasa][:home_dir] do
  recursive true
  action :create
  user node[:opsworks_custom_cookbooks][:user]
  group node[:opsworks_custom_cookbooks][:group]
  mode 00750
end
cookbook_dest = node[:tabula_rasa][:home_dir] + '/cookbooks'
cache_dir = node[:tabula_rasa][:home_dir] + '/cache'

[ cookbook_dest, cache_dir ].each do |dir| 
  directory dir do
    recursive true
    action :create
    user node[:opsworks_custom_cookbooks][:user]
    group node[:opsworks_custom_cookbooks][:group]
    mode 00750
  end
end

# Get the cookbooks

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
config_file = node[:tabula_rasa][:home_dir] + '/chef-client-config.rb'
template config_file do
  source 'chef-client-config.rb.erb'
  user 'root'
  group 'root'
  mode 00400
end

latest_json_file = ::Dir.glob('/var/lib/aws/opsworks/chef/*').sort.keep_if { |i| i.end_with?('.json') }.last

# Run the chef client
execute "run chef client" do
  user 'root'
  group 'root'
  cwd node[:tabula_rasa][:home_dir]
  command "/opt/aws/opsworks/current/bin/chef-client -j #{latest_json_file} -c #{config_file} -o #{recipes.join(',')} 2>&1"
end
  
