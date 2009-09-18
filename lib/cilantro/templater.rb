# template :index
# template :index, :layout => :bunnies
# template.flash "You've won!"
# template.user = "Jon Doe"
# return template.to_html
module Cilantro
  class Layout
    class << self
      def get_layout(name, ext=nil)
        if file = Dir.glob("#{APP_ROOT}/app/views/layouts/#{name}.#{ext ? ext : '*'}")[0]
          return file.match(/\.([^\.]+)$/)[1].to_sym, file, File.read(file)
        end
      end
    end

    attr_reader :name, :locals

    def initialize(name)
      @name = name
      @locals = {}
      # load template helper if present
      if layout_helper = Layout.get_layout(@name, 'rb')
        instance_eval(layout_helper.last)
      end
      @layout = Layout.get_layout(@name)
    end

    def render(content_for_layout)
      Template.engine(@layout.first).render(@layout, self, locals.merge(:content_for_layout => content_for_layout))
    end

    # def insert_section(name)
    #   return [] unless @locals[:"unrendered_#{name}"].is_a?(Array)
    #   @locals[name.to_sym] = @locals.delete(:"unrendered_#{name}").collect do |section|
    #     render(section, self, @locals)
    #   end
    # end
    def insert_section(name)
      return [] unless @locals[:"unrendered_#{name}"].is_a?(Array)
      @locals[name.to_sym] = @locals.delete(:"unrendered_#{name}").collect do |section|
        is_a?(Template) ? render(section, self, @locals) : Template.engine('haml').render(section, self, @locals)
      end
      puts "Rendered: #{@locals[name.to_sym].inspect}"
      @locals[name.to_sym]
    end

    def method_missing(name, value=nil)
      sign = if name.to_s =~ /^(.*)([\=\?])$/
        name = $1.to_sym
        $2
      else
        ''
      end

      case sign
      when '='
        @locals[name] = value
      when '?'
        return @locals.has_key?(name) || @locals.has_key?(:"unrendered_#{name}")
      else
        if value
          @locals[name] = value
        else
          return insert_section(name) if !@locals.has_key?(name) && @locals.has_key?(:"unrendered_#{name}")
          return @locals[name]
        end
      end

      return self
    end
  end

  class Template < Layout
    class << self
      def options
        @options ||= {
          :default_layout => :default,
          :partial_prefix => '_'
        }
      end

      def get_template(name, scope='/', ext=nil)
        view_paths(scope).each do |vp|
          if file = Dir.glob(File.join([vp, "#{name}.#{ext ? ext : '*'}"]))[0]
            return file.match(/\.([^\.]+)$/)[1].to_sym, file, File.read(file)
          end
        end
        nil
      end
      
      def get_partial(name, scope='/', ext=nil)
        view_paths(scope).each do |vp|
          if file = Dir.glob(File.join([vp, "#{options[:partial_prefix]}#{name}.#{ext ? ext : '*'}"]))[0]
            return file.match(/\.([^\.]+)$/)[1].to_sym, file, File.read(file)
          end
        end
        nil
      end

      def engine(type)
        @engine ||= {}
        @engine[type] ||= begin
          require File.dirname(__FILE__) + '/templater/' + type.to_s
          Cilantro::Template.const_get(type.to_s.capitalize!).new(options)
        end
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

    def initialize(name, scope, locals={})
      @name = name
      @scope = scope
      @locals = locals
      @layout = Layout.new(locals.delete(:layout) || self.class.options[:default_layout])
      # load view helpers
      if template_helper = Template.get_template(@name, @scope, 'rb')
        instance_eval(template_helper.last)
      end
    end

    def to_html
      @html ||= begin
        content_for_layout = render(Template.get_template(@name, @scope), self, locals)
        @layout ?
          @layout.render(content_for_layout) :
          content_for_layout
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
        # Catch locals set by the partial helper.
        old_locals = @locals
        @locals = {}
        if partial_helper = Template.get_partial(name, @scope, 'rb')
          instance_eval(partial_helper.last)
        end
        new_locals.merge!(@locals)
        @locals = old_locals

        render(Template.get_partial(name, @scope), self, new_locals)
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

      # Catch things defined by the partial's helper.
      old_locals = @locals
      @locals = {}
      if partial_helper = Template.get_partial(name, @scope, 'rb')
        instance_eval(partial_helper.last)
      end
      new_locals.merge!(@locals)
      @locals = old_locals

      if looper && looper_name
        looper.collect do |single|
          render(Template.get_partial(name, @scope), self, new_locals.merge(looper_name => single))
        end.join
      else
        render(Template.get_partial(name, @scope), self, new_locals)
      end
    end

    def render(template_package, context, locals)
      self.class.engine(template_package.first).render(template_package, context, locals.merge(:layout => @layout))
    end
  end

  module Templater
    # Method: layout
    def layout(name)
      @layout_name = name
    end

    # Method: template
    def template(name=nil, locals={})
      if name.nil?
        return @template
      else
        raise ArgumentError, "The first time you call `template' you must supply the name of the template to be used!" unless name
              # caller should probably look as many levels back as necessary to find a method with a space in it.
        @template = Template.new(name, CilantroApplication.scopes[caller[0].match(/`(.*?)'/)[1]], {:layout => @layout_name}.merge(locals))
      end
      if block_given?
        yield @template
      end
      return @template
    end
  end
end

CilantroApplication.send(:include, Cilantro::Templater) if ::Object.const_defined?(:CilantroApplication)
