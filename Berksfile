#source 'http://api.berkshelf.com'
source 'http://localhost:8889' # For OpsWorks to lock down the cookbooks

metadata

Dir.glob('/opt/aws/opsworks/current/cookbooks/**').each do |path|
  cookbook File.basename(path), path: path  if File.directory?(path)
end
