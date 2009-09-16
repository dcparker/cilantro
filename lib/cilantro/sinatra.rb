require 'sinatra/base'
class CilantroApplication < Sinatra::Base
  def self.scopes
    @scopes ||= {}
  end
end
