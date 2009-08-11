require 'rubygems'

# DEPENDENCIES
require 'haml'

# APP LIBRARIES
require 'lib/require_all'
require_all 'lib/**/*.rb'

# DATAMAPPER MODELS
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
Cilantro.setup_database
require_all 'app/models/*.rb'

# Load Controllers IF Sinatra is loaded.
# This way you can require this file (and therefore the entire app) in irb,
# and it won't the controllers by default.
require_all 'app/controllers/*.rb' if ::Object.const_defined?(:Sinatra)
