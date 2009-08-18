# Should make this a full application, not a micro-app structure.
# See http://www.sinatrarb.com/intro.html, "Sinatra::Base - Middleware, Libraries, and Modular Apps"

# Main page
get '/' do
  magic :index
end

# Post a form to this url
post '/form' do
  @name = params[:name]
  magic :index
end

# Show a listing
get '/show/:id' do |id|
  @id = id
  magic :index
end

error do
  Cilantro.report_error(env['sinatra.error'])
  magic :error_page
end
