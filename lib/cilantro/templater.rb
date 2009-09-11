require 'haml'

# template :index
# template.layout
# template.flash
# template.to_html
module Cilantro
  class Template
    class << self
      def options
        @options ||= {
          :partial_prefix => '_'
        }
      end

      def get_template(name, scope='/')
        view_paths(scope).each do |vp|
          if File.exists?(File.join([vp, "#{name}.haml"]))
            return File.read(File.join([vp, "#{name}.haml"]))
          end
        end
      end
      
      def get_partial(name, scope='/')
        view_paths(scope).each do |vp|
          if File.exists?(File.join([vp, "#{name}.haml"]))
            return File.read(File.join([vp, "#{options[:partial_prefix]}#{name}.haml"]))
          end
        end
        File.read("#{APP_ROOT}/app/views/_#{name}.haml")
      end

      def get_layout(name='default')
        File.read("#{APP_ROOT}/app/views/layouts/#{name}.haml")
      end

      private
        def view_paths(scope)
          paths = scope.split('/').reject {|j| j==''}
          view_paths = ["#{APP_ROOT}/app/views"]
          paths.each do |l|
            view_paths.unshift(view_paths.first + '/' + l)
          end
          view_paths
        end
    end

    attr_reader :name, :locals

    def self.options
      @options ||= {}
    end

    def initialize(name, scope, locals={})
      @name = name
      @scope = scope
      @locals = locals
      instance_eval(File.read("#{APP_ROOT}/app/views/#{@name}.rb")) if File.exists?("#{APP_ROOT}/app/views/#{@name}.rb")
    end

    def to_html
      @html ||= begin
        content_for_layout = Haml::Engine.new(Template.get_template(@name, @scope)).render(self, locals)
        if self.class.options[:layout] == false
          content_for_layout
        else
          self.class.options[:layout] ||= :default
          Haml::Engine.new(Template.get_layout(self.class.options[:layout])).render(self, {:content_for_layout => content_for_layout})
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
        Haml::Engine.new(Template.get_partial(name, @scope)).render(self, new_locals)
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
          Haml::Engine.new(Template.get_partial(name, @scope)).render(self, new_locals.merge(looper_name => single))
        end.join
      else
        Haml::Engine.new(Template.get_partial(name, @scope)).render(self, new_locals)
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
    # Method: template
    def template(name=nil, locals={})
      if name.nil?
        return @template
      else
              # caller should probably look as many levels back as necessary to find a method with a space in it.
        @template = Template.new(name, Application.scopes[caller[0].match(/`(.*?)'/)[1]], locals)
      end
      if block_given?
        yield @template
      end
      return @template
    end
  end
end

Application.send(:include, Cilantro::Templater) if ::Object.const_defined?(:Application)
