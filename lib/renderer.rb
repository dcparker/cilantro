module Renderer
  def magic(view_name, options={})
    content_for_layout = view_name.is_a?(String) ? view_name : haml(File.read("app/views/#{view_name}.haml"))
    if options[:layout] == false
      content_for_layout
    else
      options[:layout] ||= :default
      haml File.read("app/views/layouts/#{options[:layout]}.haml"), :locals => {:content_for_layout => content_for_layout}
    end
  end

  def partial(partial_name)
    haml(File.read("app/views/_#{partial_name}.haml"))
  end
end

include Renderer
