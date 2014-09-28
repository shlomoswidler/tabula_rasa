name             'tabula_rasa'
maintainer       'Shlomo Swidler'
maintainer_email 'shlomo.swidler@orchestratus.com'
license          'Copyright 2014, Shlomo Swidler. All Rights Reserved'
description      'Experiment'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

supports "ubuntu", "= 12.04"

recipe "default", "Sets up and runs the tabula-rasa recipes"
