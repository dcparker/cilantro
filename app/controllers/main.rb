# Should make this a full application, not a micro-app structure.
# See http://www.sinatrarb.com/intro.html, "Sinatra::Base - Middleware, Libraries, and Modular Apps"

class Main
  include Cilantro::Controller

  scope '/'

  # Main page
  get '' do
    template :index
  end

  # Post a form to this url
  post 'form' do
    @name = params[:name]
    template :index
  end

  scope 'listings' do

    # Show a listing
    get ':id' do |id|
      @id = id
      template :index
    end

  end

  get '', :host => /^api\./ do
    # Show something for a 'GET /' request to subdomain 'api' (GET http://api.domain.com/)
  end

  error do
    Cilantro.report_error(env['sinatra.error'])
    template :error_page
  end
end
