site_cookbooks_path = ::File.join(node[:tabula_rasa][:home_dir], 'site-cookbooks')
berkshelf_cookbooks_path = ::File.join(node[:tabula_rasa][:home_dir], 'berkshelf-cookbooks')
merged_cookbooks_path = ::File.join(node[:tabula_rasa][:home_dir], 'merged-cookbooks')

# Get the cookbooks

## From opsworks-cookbooks/opsworks_custom_cookbooks/recipes/load.rb
case node[:tabula_rasa][:scm][:type]
when 'git'
  git "Download Tabula-Rasa Cookbooks" do
    enable_submodules node[:tabula_rasa][:scm][:enable_submodules]
    depth nil

    user node[:opsworks_custom_cookbooks][:user]
    group node[:opsworks_custom_cookbooks][:group]
    action :checkout
    destination site_cookbooks_path
    repository node[:tabula_rasa][:scm][:repository]
    revision node[:tabula_rasa][:scm][:revision]
    retries 2
    not_if do
      node[:tabula_rasa][:scm][:repository].blank? || ::File.directory?(site_cookbooks_path)
    end
  end
when 'svn'
  subversion "Download Tabula-Rasa Cookbooks" do
    svn_username node[:tabula_rasa][:scm][:user]
    svn_password node[:tabula_rasa][:scm][:password]

    user node[:opsworks_custom_cookbooks][:user]
    group node[:opsworks_custom_cookbooks][:group]
    action :checkout
    destination site_cookbooks_path
    repository node[:tabula_rasa][:scm][:repository]
    revision node[:tabula_rasa][:scm][:revision]
    retries 2
    not_if do
      node[:tabula_rasa][:scm][:repository].blank? || ::File.directory?(site_cookbooks_path)
    end
  end
else
  raise "unsupported SCM type #{node[:tabula_rasa][:scm][:type].inspect}"
end

ruby_block 'Move single Tabula-Rasa cookbook contents into appropriate subdirectory' do
  block do
    cookbook_name = File.readlines(File.join(site_cookbooks_path, 'metadata.rb')).detect{|line| line.match(/^\s*name\s+\S+$/)}[/name\s+['"]([^'"]+)['"]/, 1]
    cookbook_path = File.join(site_cookbooks_path, cookbook_name)
    Chef::Log.info "Single cookbook detected, moving into subdirectory '#{site_cookbooks_path}'"
    FileUtils.mkdir(cookbook_path)
    Dir.glob(File.join(site_cookbooks_path, '*'), File::FNM_DOTMATCH).each do |cookbook_content|
      FileUtils.mv(cookbook_content, cookbook_path, :force => true)
    end
  end

  only_if do
    ::File.exists?(metadata = File.join(site_cookbooks_path, 'metadata.rb')) && File.read(metadata).match(/^\s*name\s+\S+$/)
  end
end

include_recipe "tabula_rasa::berkshelf"

execute "ensure correct permissions of Tabula-Rasa site cookbooks" do
  command "chmod -R go-rwx #{site_cookbooks_path}"
  only_if do
    ::File.exists?(site_cookbooks_path)
  end
end

ruby_block 'merge all Tabula-Rasa cookbooks sources' do
  block do
     FileUtils.rm_rf merged_cookbooks_path
     FileUtils.cp_r "#{berkshelf_cookbooks_path}/.", merged_cookbooks_path if ::File.directory?(berkshelf_cookbooks_path)
     FileUtils.cp_r "#{site_cookbooks_path}/.", merged_cookbooks_path if ::File.directory?(site_cookbooks_path)
  end
end
