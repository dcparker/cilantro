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
