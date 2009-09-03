require 'haml'

# template :index
# template.layout
# template.flash
# template.to_html

class Template
  attr_reader :name, :locals

  def self.options
    @options ||= {}
  end

  def initialize(name)
    @name = name
    @locals = {}
    instance_eval(File.read("#{APP_ROOT}/app/views/#{@name}.rb")) if File.exists?("#{APP_ROOT}/app/views/#{@name}.rb")
  end

  def to_html
    content_for_layout = Haml::Engine.new(File.read("#{APP_ROOT}/app/views/#{@name}.haml")).render(self, locals)
    if self.class.options[:layout] == false
      content_for_layout
    else
      self.class.options[:layout] ||= :default
      Haml::Engine.new(File.read("#{APP_ROOT}/app/views/layouts/#{self.class.options[:layout]}.haml")).render(self, {:content_for_layout => content_for_layout})
    end
  end

  def method_missing(name, *values)
    @locals[name] = values[0]
  end
end

module Cilantro
  module Controller
    # Method: template
    def template(name=nil)
      if name.nil?
        return @template
      else
        @template = Template.new(name)
      end
      return @template
    end
  end
end
