# File: config/init.rb
# Sets up configurations and includes gems, libraries, controllers & models.
# To start the web server, use bin/cilantro.
# 
# To be loaded ONLY by Cilantro.load_environment. Already done at this point:
#   + ./lib is included in the ruby load path
#   + rubygems is loaded, but sandboxed to ./gems if ./gems exists
#   + if we're running in server or test mode, sinatra has been loaded

###################
# Section: Dependencies and Libraries
require 'haml'
require 'cilantro/templater'

###################
# Section: Database Setup
# Fires up a connection to the database using settings from config/database.yml config
# require 'dm-core'
# require 'dm-validations'
# require 'dm-migrations'
# Cilantro.setup_database
