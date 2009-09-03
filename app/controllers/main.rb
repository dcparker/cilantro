# Should make this a full application, not a micro-app structure.
# See http://www.sinatrarb.com/intro.html, "Sinatra::Base - Middleware, Libraries, and Modular Apps"

class Main
  include Cilantro::Controller

  scope '/'

  # Main page
  get '' do
    magic :index
  end

  # Post a form to this url
  post 'form' do
    @name = params[:name]
    magic :index
  end

  scope 'show' do
    # Show a listing
    get ':id' do |id|
      @id = id
      magic :index
    end
  end

  error do
    Cilantro.report_error(env['sinatra.error'])
    magic :error_page
  end
end
