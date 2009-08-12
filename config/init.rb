require 'rubygems'

# DEPENDENCIES
require 'haml'

# APP LIBRARIES
require File.expand_path(File.dirname(__FILE__) + '/../lib') + '/cilantro'

# DATAMAPPER MODELS
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
Cilantro.setup_database
require_all 'lib/**/*.rb'
require_all 'app/models/*.rb'

# Load Controllers IF Sinatra is loaded.
# This way you can require this file (and therefore the entire app) in irb,
# and it won't the controllers by default.
if ::Object.const_defined?(:Sinatra)
  Sinatra::Application.set :public, 'public'
  Sinatra::Application.set :static, true
  require_all 'app/controllers/*.rb'
end
