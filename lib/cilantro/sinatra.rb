require 'sinatra/base'
class Application < Sinatra::Base
  def self.scopes
    @scopes ||= {}
  end
end
