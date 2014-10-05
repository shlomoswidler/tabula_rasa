site_cookbooks_path = ::File.join(node[:tabula_rasa][:home_dir], 'site-cookbooks')
berkshelf_cookbooks_path = ::File.join(node[:tabula_rasa][:home_dir], 'berkshelf-cookbooks')
merged_cookbooks_path = ::File.join(node[:tabula_rasa][:home_dir], 'merged-cookbooks')

# Get the cookbooks
## From opsworks-cookbooks/opsworks_custom_cookbooks/recipes/checkout.rb
ensure_scm_package_installed(node[:tabula_rasa][:scm][:type]) unless node[:tabula_rasa][:scm][:type].nil?

prepare_git_checkouts(:user => node[:opsworks_custom_cookbooks][:user],
                      :group => node[:opsworks_custom_cookbooks][:group],
                      :home => node[:opsworks_custom_cookbooks][:home],
                      :ssh_key => node[:tabula_rasa][:scm][:ssh_key]) if node[:tabula_rasa][:scm][:type].to_s == 'git'

prepare_svn_checkouts(:user => node[:opsworks_custom_cookbooks][:user],
                      :group => node[:opsworks_custom_cookbooks][:group],
                      :home => node[:opsworks_custom_cookbooks][:home],
                      :deploy => node[:tabula_rasa]) if node[:tabula_rasa][:scm][:type].to_s == 'svn'

if node[:tabula_rasa][:scm][:type].to_s == 'archive'
  repository = prepare_archive_checkouts(node[:tabula_rasa][:scm])
  node.set[:tabula_rasa][:scm] = {
    :type => 'git',
    :repository => repository
  }
elsif node[:tabula_rasa][:scm][:type].to_s == 's3'
  repository = prepare_s3_checkouts(node[:tabula_rasa][:scm])
  node.set[:tabula_rasa][:scm] = {
   :type => 'git',
   :repository => repository
  }
end

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
