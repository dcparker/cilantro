require 'haml'

# template :index
# template.layout
# template.flash
# template.to_html
module Cilantro
  class Template
    attr_reader :name, :locals

    def self.options
      @options ||= {}
    end

    def initialize(name, locals={})
      @name = name
      @locals = locals
      instance_eval(File.read("#{APP_ROOT}/app/views/#{@name}.rb")) if File.exists?("#{APP_ROOT}/app/views/#{@name}.rb")
    end

    def to_html
      @html ||= begin
        content_for_layout = Haml::Engine.new(Templater.get_template(@name)).render(self, locals)
        if self.class.options[:layout] == false
          content_for_layout
        else
          self.class.options[:layout] ||= :default
          Haml::Engine.new(Templater.get_layout(self.class.options[:layout])).render(self, {:content_for_layout => content_for_layout})
        end
      end
    end
    alias :to_str :to_html
    alias :to_s :to_str
    def bytesize
      to_html.bytesize
    end

    def partial(name, new_locals={})
      if locals.has_key?(:with)
        partials(name, new_locals)
      else
        Haml::Engine.new(Templater.get_partial(name)).render(self, new_locals)
      end
    end

    def partials(name, new_locals={})
      if new_locals.has_key?(:with)
        looper = new_locals.delete(:with)
        looper_name = new_locals.delete(:as) || name
      elsif new_locals.values.first.is_a?(Enumerable)
        looper_name = new_locals.keys.first
        looper = new_locals.delete(looper_name)
      end

      if looper && looper_name
        looper.collect do |single|
          Haml::Engine.new(Templater.get_partial(name)).render(self, new_locals.merge(looper_name => single))
        end.join
      else
        Haml::Engine.new(Templater.get_partial(name)).render(self, new_locals)
      end
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
    class << self
      def get_template(name)
        File.read("#{APP_ROOT}/app/views/#{name}.haml")
      end
      
      def get_partial(name)
        File.read("#{APP_ROOT}/app/views/_#{name}.haml")
      end

      def get_layout(name='default')
        File.read("#{APP_ROOT}/app/views/layouts/#{name}.haml")
      end
    end

    # Method: template
    def template(name=nil, locals={})
      if name.nil?
        return @template
      else
        @template = Template.new(name, locals)
      end
      if block_given?
        yield @template
      end
      return @template
    end
  end
end

Application.send(:include, Cilantro::Templater) if ::Object.const_defined?(:Application)
