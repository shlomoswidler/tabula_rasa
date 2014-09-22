name             'tabula_rasa'
maintainer       'Shlomo Swidler'
maintainer_email 'shlomo.swidler@orchestratus.com'
license          'Apache License 2.0'
description      'Allow community cookbooks to run without interference from AWS OpsWorks cookbooks'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

supports "ubuntu", "= 12.04"

recipe "default", "Sets up and runs the tabula-rasa recipes"
