require 'rubygems'

# DEPENDENCIES
require 'Haml'

# APP LIBRARIES
require 'lib/require_all'
require_all 'lib/**/*.rb'

# DATAMAPPER MODELS
# require 'dm-core'
# require 'dm-validations'
# require 'dm-timestamps'
# DataMapper.setup(:default, "sqlite3:///#{Dir.pwd}/config/development.sqlite")
# require_all 'app/models/*.rb'

# Load Controllers IF Sinatra is loaded.
# This way you can require this file (and therefore the entire app) in irb,
# and it won't the controllers by default.
require_all 'app/controllers/*.rb' if ::Object.const_defined?(:Sinatra)

# Load Environment Config
APP_CONFIG = YAML.load_file('config/env_config.yml')
