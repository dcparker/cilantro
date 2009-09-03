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
    @html ||= begin
      content_for_layout = Haml::Engine.new(File.read("#{APP_ROOT}/app/views/#{@name}.haml")).render(self, locals)
      if self.class.options[:layout] == false
        content_for_layout
      else
        self.class.options[:layout] ||= :default
        Haml::Engine.new(File.read("#{APP_ROOT}/app/views/layouts/#{self.class.options[:layout]}.haml")).render(self, {:content_for_layout => content_for_layout})
      end
    end
  end
  alias :to_str :to_html
  alias :to_s :to_str
  def bytesize
    to_html.bytesize
  end

  def method_missing(name, value=nil)
    sign = if name =~ /([\=\?])$/
      name.chop!
      $1
    else
      ''
    end

    case sign
    when '='
      @locals[name] = value
    when '?'
      @locals.has_key?(name)
    else
      if value
        @locals[name] = value
      else
        @locals[name]
      end
    end
    return @template
  end
end

module Templater
  # Method: template
  def template(name=nil)
    if name.nil?
      return @template
    else
      @template = Template.new(name)
    end
    if block_given?
      yield @template
    end
    return @template
  end
end

Application.send(:include, Templater)
