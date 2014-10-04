name             'tabula_rasa'
maintainer       'Shlomo Swidler'
maintainer_email 'shlomo.swidler@orchestratus.com'
license          'Apache 2.0'
description      'Run community cookbooks from within AWS OpsWorks without clashing with the older versions in opsworks-cookbooks'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

supports "ubuntu", "= 12.04"

depends "scm_helper"
depends "opsworks_berkshelf"
depends "opsworks_custom_cookbooks"

recipe "default", "Sets up and runs"
recipe "update_tabula_rasa_cookbooks", "Updates the Tabla Rasa cookbooks"
