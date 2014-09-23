# TODO: Support specified URL for the package
# TODO: Support verifying the hashes of the OpsCode-provided bundle (via the metadata? URL action)

sha256checksum = nil

package_dir = node[:tabula_rasa][:home_dir] + '/cache'

directory package_dir do
  recursive true
  action :create
  user 'root'
  group 'root'
  mode 00700
end

remote_file package_dir + '/chef-client-package.deb' do
  checksum sha256checksum if sha256checksum
  source 'https://www.getchef.com/chef/download?p=ubuntu&pv=12.04&v=11.10&m=x86_64'
  user 'root'
  group 'root'
  mode 00750
  notifies :run, 'execute[install chef-client deb]', :immediately
end

execute "install chef-client deb" do
  user 'root'
  group 'root'
  cwd package_dir
  command "DEBIAN_FRONTEND=noninteractive dpkg --debug=1 -i chef-client-package.deb"
  action :nothing
end
