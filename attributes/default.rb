include_attribute "opsworks_berkshelf::default"
include_attribute "opsworks_custom_cookbooks::default"

default[:tabula_rasa][:chef_version] = '11.10'
default[:tabula_rasa][:recipes] = {}
default[:tabula_rasa][:home_dir] = '/home/tabula-rasa'

default[:tabula_rasa][:scm][:type] = nil
default[:tabula_rasa][:scm][:repository] = nil
default[:tabula_rasa][:scm][:user] = nil
default[:tabula_rasa][:scm][:password] = nil
default[:tabula_rasa][:scm][:revision] = 'HEAD'
default[:tabula_rasa][:scm][:ssh_key] = node[:opsworks_custom_cookbooks][:scm][:ssh_key]
default[:tabula_rasa][:scm][:enable_submodules] = node[:opsworks_custom_cookbooks][:scm][:enable_submodules]

