require_with_auto_install 'sinatra/base', :gem => 'sinatra'
Sinatra.send(:remove_const, :Templates)
class Application < Sinatra::Base
  include Cilantro::Application
end
