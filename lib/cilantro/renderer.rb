module Kernel
  def render(view_name, options={})
    content_for_layout = haml(File.read("#{APP_ROOT}/app/views/#{view_name}.haml"))
    if options[:layout] == false
      content_for_layout
    else
      options[:layout] ||= :default
      haml File.read("#{APP_ROOT}/app/views/layouts/#{options[:layout]}.haml"), :locals => {:content_for_layout => content_for_layout}
    end
  end

  def partial(partial_name)
    haml(File.read("#{APP_ROOT}/app/views/_#{partial_name}.haml"))
  end
end
# include Renderer
