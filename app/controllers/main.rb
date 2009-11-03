class Main < Application

  scope '/'

  # Main page
  get '' do
    template :index, :msg => msg
  end

  # Post a form to this url
  post 'contact_us' do
    template :index, :name => params[:name], :id => 'hi'
  end

  # This is not yet scoped to just one controller or scope.
  error do
    Cilantro.report_error(env['sinatra.error'])
    template :error_page
  end

  helper :msg do
    'Hello, World!'
  end
end
