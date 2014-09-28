# Based on opsworks-cookbooks/opsworks_berkshelf/providers/runner.rb
site_cookbooks_dir = ::File.join(node[:tabula_rasa][:home_dir], 'site-cookbooks')
berkshelf_cookbooks_dir = ::File.join(node[:tabula_rasa][:home_dir],'berkshelf-cookbooks')

ruby_block "show opsworks chef attributes" do
  block do
    puts "ATTENTION: opsworks_berkshelf: #{node['opsworks_berkshelf'].inspect}"
    puts "ATTENTION: opsworks_custom_cookbooks: #{node['opsworks_custom_cookbooks'].inspect}"
  end
end

berks_install_options = if node['opsworks-berkshelf'] && node['opsworks_berkshelf']['version'].to_i >= 3
  "vendor #{berkshelf_cookbooks_dir}"
else
  "install --path #{berkshelf_cookbooks_dir}"
end

berks_install_options += ' --debug' if node['opsworks-berkshelf'] && node['opsworks_berkshelf']['debug']
berks_install_command = "/opt/aws/opsworks/local/bin/berks #{berks_install_options}"

directory berkshelf_cookbooks_dir do
  action :delete
  recursive true

  only_if do
    node['opsworks_berkshelf'] && node['opsworks_berkshelf']['version'].to_i >= 3
  end
end

ruby_block 'Install the cookbooks specified in the Tabula Rasa cookbook\'s Berksfile and their dependencies' do
  block do
    
    # TODO: This snippet is repeated in the only_if block below. Bad style.
     berksfile_top = ::File.join(site_cookbooks_dir, 'Berksfile')
    # only return Berksfile if there is exactly one folder no matter if this folder contains a berksfile or not
    folders = Dir.glob(::File.join(site_cookbooks_dir, '*')).select { |f| ::File.directory? f }

    if ::File.exist? berksfile_top
      berksfile = berksfile_top
    elsif folders.size == 1
      berksfile = ::File.join(folders.first, 'Berksfile')
    else
      berksfile = ''
    end
    
    Chef::Log.info OpsWorks::ShellOut.shellout(
      berks_install_command,
      :cwd => ::File.dirname(berksfile),
      :environment  => {
        "BERKSHELF_PATH" => ::File.join(node[:tabula_rasa][:home_dir], 'cache')
      }
    )
  end

  only_if do
    # TODO: This snippet is a duplicate of that foudn in the block above. Bad style.
    berksfile_top = ::File.join(site_cookbooks_dir, 'Berksfile')
    # only return Berksfile if there is exactly one folder no matter if this folder contains a berksfile or not
    folders = Dir.glob(::File.join(site_cookbooks_dir, '*')).select { |f| ::File.directory? f }

    if ::File.exist? berksfile_top
      berksfile = berksfile_top
    elsif folders.size == 1
      berksfile = ::File.join(folders.first, 'Berksfile')
    else
      berksfile = ''
    end  
    ::File.exist?('/opt/aws/opsworks/local/bin/berks') && ::File.exist?(berksfile)
  end
end

