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

module Cilantro
  class << self
    def setup_database
      if File.exists?('config/database.yml')
        # warn if config does not have necessary values in it
        DataMapper.setup(:default, YAML.load_file('config/database.yml'))
      else
        warn "Cannot set up the database: config/database.yml missing!"
        exit
      end
    end
  end
end
