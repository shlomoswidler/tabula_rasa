activity = node[:opsworks][:activity]
recipes = node[:tabula_rasa][:recipes][activity]
return if recipes.nil? || recipes.size == 0

directory node[:tabula_rasa][:home_dir] do
  recursive true
  action :create
  user node[:opsworks_custom_cookbooks][:user]
  group node[:opsworks_custom_cookbooks][:group]
  mode 00750
end

cache_dir = ::File.join(node[:tabula_rasa][:home_dir], 'cache')

directory cache_dir do
  recursive true
  action :create
  user node[:opsworks_custom_cookbooks][:user]
  group node[:opsworks_custom_cookbooks][:group]
  mode 00750
end

merged_cookbooks_path = ::File.join(node[:tabula_rasa][:home_dir], 'merged-cookbooks')

include_recipe "tabula_rasa::prepare_cookbooks"

# Prepare the config for the chef client run
config_file = ::File.join(node[:tabula_rasa][:home_dir], 'chef-client-config.rb')
template config_file do
  source 'chef-client-config.rb.erb'
  variables( :cookbook_path => merged_cookbooks_path,
    :cache_path => cache_dir )
  user 'root'
  group 'root'
  mode 00400
end

# Assumption: The most recent JSON file is the one for the current OpsWorks agent invocation.
latest_json_file = ::Dir.glob('/var/lib/aws/opsworks/chef/*').sort.keep_if { |i| i.end_with?('.json') }.last

# Run the chef client
ruby_block 'run Tabula-Rasa chef-client' do
  block do
    Chef::Log.info OpsWorks::ShellOut.shellout(
      "/opt/aws/opsworks/current/bin/chef-client -j #{latest_json_file} -c #{config_file} -o #{recipes.join(',')} 2>&1",
      :cwd => node[:tabula_rasa][:home_dir]
    )
  end
end
