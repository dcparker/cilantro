# File: sandbox_gems.rb
#
# Discription:
# Sandboxes the local gems folder.

APP_ROOT = File.expand_path(Dir.pwd) unless defined?(APP_ROOT)

require 'rubygems'
require 'rubygems/custom_require'

if File.exists?("#{APP_ROOT}/gems")
  # Oh but first, go ahead and install any missing gems (PLEASE, only include gems/specifications and gems/cache in your git repo)
    require File.dirname(__FILE__) + '/install_missing_gems'
  Gem.use_paths("#{APP_ROOT}/gems", ["#{APP_ROOT}/gems"])
end