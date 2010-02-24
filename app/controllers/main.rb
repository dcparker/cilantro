class Main < Application
  namespace '/'

  get :home do
    view :index
  end

  # Main page
  get 'new_index' do
    view :index
  end

  # This is not yet limited to just one controller or namespace.
  error do
    Cilantro.report_error(env['sinatra.error'])
    view :default_error_page
  end
end
