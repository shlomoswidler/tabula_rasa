include_attribute "opsworks_berkshelf::default"

default[:tabula_rasa][:chef_version] = '11.10'
default[:tabula_rasa][:recipes] = {}
default[:tabula_rasa][:home_dir] = '/home/tabula-rasa'

default[:tabula_rasa][:scm][:type] = 'none'
default[:tabula_rasa][:scm][:repository] = nil
default[:tabula_rasa][:scm][:user] = nil
default[:tabula_rasa][:scm][:password] = nil
default[:tabula_rasa][:scm][:revision] = nil
default[:tabula_rasa][:scm][:ssh_key] = nil
default[:tabula_rasa][:scm][:enable_submodules] = true

