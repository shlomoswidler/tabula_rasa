# Based on opsworks-cookbooks/opsworks_berkshelf/providers/runner.rb

site_cookbooks_dir = ::File.join(node[:tabula_rasa][:home_dir], 'site-cookbooks')
berkshelf_cookbooks_dir = ::File.join(node[:tabula_rasa][:home_dir],'berkshelf-cookbooks')

directory berkshelf_cookbooks_dir do
  action :delete
  recursive true

  only_if do
    node['opsworks_berkshelf']['version'].to_i >= 3
  end
end

ruby_block 'Install the cookbooks specified in the Tabula Rasa\'s cookbook Berksfile and their dependencies' do
  block do
    Chef::Log.info OpsWorks::ShellOut.shellout(
      berks_install_command,
      :cwd => ::File.dirname(berksfile),
      :environment  => {
        "BERKSHELF_PATH" => ::File.join(node[:tabula_rasa][:home_dir], 'cache')
      }
    )
  end

  only_if do
    ::File.exist?(::File.join('/opt/aws/opsworks/local/bin', 'berks')) && ::File.exist?(berksfile)
  end
end

def berksfile
  berksfile_top = ::File.join(site_cookbooks_dir, 'Berksfile')
  # only return Berksfile if there is exactly one folder no matter if this folder contains a berksfile or not
  folders = Dir.glob(::File.join(site_cookbooks_dir, '*')).select { |f| ::File.directory? f }

  if ::File.exist? berksfile_top
    berksfile_top
  elsif folders.size == 1
    ::File.join(folders.first, 'Berksfile')
  else
    ''
  end
end

def berks_install_command
  options = if node['opsworks_berkshelf']['version'].to_i >= 3
    "vendor #{berkshelf_cookbooks_dir}"
  else
    "install --path #{berkshelf_cookbooks_dir}"
  end

  options += ' --debug' if node['opsworks_berkshelf']['debug']

  "#{OpsWorks::Berkshelf.berkshelf_binary} #{options}"
end
