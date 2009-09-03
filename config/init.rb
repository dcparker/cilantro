# File: config/init.rb
# Sets up configurations and includes gems, libraries, controllers & models.
# To start the web server, use bin/cilantro.
# 
# To be loaded ONLY by Cilantro.load_environment. Already done at this point:
#   + ./lib is included in the ruby load path
#   + rubygems is loaded, but sandboxed to ./gems if ./gems exists
#   + if we're running in server or test mode, sinatra has been loaded

# DEPENDENCIES
require 'haml'

###################
# Section: Database Setup
# Fires up a connection to the database using settings from config/database.yml config
# require 'dm-core'
# require 'dm-validations'
# require 'dm-migrations'
# Cilantro.setup_database

###################
# Section: Application Libraries
# Inludes: lib/*.rb, app/models/*.rb & app/controllers/*.rb
Dir.glob("#{APP_ROOT}/lib/*.rb").each {|lib_rb| require lib_rb.split('/').last } # lib/*.rb

if RACK_ENV != 'irb' # app/controllers/*.rb
  Application.set :static => true, :public => 'public'
  Dir.glob("#{APP_ROOT}/app/controllers/*.rb").each {|file| require file}
end

Dir.glob("#{APP_ROOT}/app/models/*.rb").each {|file| require file} # app/models/*.rb
