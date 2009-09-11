class Main
  include Cilantro::Controller

  scope '/'

  # Main page
  get '' do
    template :index, :msg => 'Peek-a-boo!'
  end

  # Post a form to this url
  post 'form' do
    template :index, :name => params[:name], :id => 'hi'
  end

  scope 'listings' do

    # Show a listing
    get ':id' do |id|
      @id = id
      template :index
    end

  end

  # get '', :host => /^api\./ do
  #   # Show something for a 'GET /' request to subdomain 'api' (GET http://api.domain.com/)
  # end

  error do
    Cilantro.report_error(env['sinatra.error'])
    template :error_page
  end
end
