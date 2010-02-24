module Cilantro
  # Views
  # Methods available publicly on a view:
  #   .to_s
  #   .to_str
  #   .to_html
  #   .to_json
  #   .to_xml
  #   .coerce
  # All other methods called shall be handled by method_missing.
  class Template < String
    include Cilantro::Application
    class << self
      def markups
        @markups ||= []
      end
      def register_markup(match, klass)
        markups << [match, klass]
      end

      def options
        @options ||= {
          :default_layout => :default,
          :partial_prefix => '_'
        }
      end

      def get_view(name, namespace='/', ext=nil)
        view_paths(namespace).each do |vp|
          if file = Dir.glob(File.join([vp, "#{name}.#{ext ? ext : '*'}"]))[0]
            return file, File.read(file)
          end
        end
        nil
      end
      
      def get_partial(name, namespace='/', ext=nil)
        view_paths(namespace).each do |vp|
          if file = Dir.glob(File.join([vp, "#{options[:partial_prefix]}#{name}.#{ext ? ext : '*'}"]))[0]
            return file, File.read(file)
          end
        end
        nil
      end

      def engine(filename)
        markups = []
        begin
          none_found = true
          Cilantro::Template.markups.each do |f|
            if filename =~ f[0]
              markups << f
              # Chop off the end so we can now determine the next type
              filename = filename.sub(f[0],'')
              none_found = false
              break
            end
          end
        end until markups.last == Cilantro::Template.markups.last || none_found
        markups.unshift(markups.pop) # Rotate the plaintext markup to the beginning
        raise RuntimeError, "Fatal Templater error: NO RENDERER found for file `#{filename}'" if markups.empty?
        # Now we'll make the cascading renderer.
        markups.inject(nil) do |last, markup|
          Cilantro::Template.const_get(markup[1].to_s).new(options.merge(:upstream => last))
        end
      end

      private
        def view_paths(namespace)
          paths = namespace.split('/').reject {|j| j==''}
          view_paths = ["#{APP_ROOT}/app/views"]
          paths.each do |l|
            view_paths.unshift(view_paths.first + '/' + l)
          end
          view_paths
        end
    end

    attr_accessor :name
    attr_reader :locals

    def initialize(controller, name, locals={})
      @controller = controller
      @name = name
      @locals = {:layout => self.class.options[:default_layout]}.merge(locals)
    end

    def set_namespace(namespace)
      @namespace = namespace[1]
      @layout = Layout.new(@controller, locals.delete(:layout), @namespace) if locals[:layout]
      # load view helpers
      if view_helper = Template.get_view(@name, @namespace, 'rb')
        @html = :helper
        instance_eval(view_helper.last)
        @html = :rendering
      end
    end

    def url(*args)
      begin
        @controller.url(*args)
      rescue => e
        raise RuntimeError, e.to_s, caller
      end
    end

    def to_html
      @html ||= begin
        @html = :rendering
        replace @name.inspect + ' in ' + @namespace
        if view = Template.get_view(@name, @namespace)
          content_for_layout = render(view, self, locals)
          @layout ?
            @layout.render!(content_for_layout) :
            content_for_layout
        else
          raise RuntimeError, "Could not find view `#{@name}' from namespace #{@namespace}", caller
        end
      end
      replace @html
      @html
    end
    def to_json(*args)
      dependency 'json'
      locals.to_json(*args)
    end
    def to_xml
      locals.to_xml
    end

    # These are to make Cilantro Templates work with Sinatra and Rack.
    alias :to_str :to_html
    alias :to_s :to_str
    def bytesize
      to_html.bytesize
    end
    alias :size :bytesize
    def instance_of?(klass)
      return true if klass == String
      super
    end
    # ****

    def partial(name, new_locals={})
      if locals.has_key?(:with)
        partials(name, new_locals)
      else
        # Catch locals set by the partial helper.
        old_locals = @locals
        @locals = {}
        if partial_helper = Template.get_partial(name, @namespace, 'rb')
          @html = :helper
          instance_eval(partial_helper.last)
          @html = :rendering
        end
        new_locals.merge!(@locals)
        @locals = old_locals

        if partl = Template.get_partial(name, @namespace)
          render(partl, self, new_locals)
        else
          raise RuntimeError, "Could not find partial `_#{name}' from namespace #{@namespace}", caller
        end
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
      if partial_helper = Template.get_partial(name, @namespace, 'rb')
        @html = :helper
        instance_eval(partial_helper.last)
        @html = :rendering
      end
      new_locals.merge!(@locals)
      @locals = old_locals

      if partl = Template.get_partial(name, @namespace)
        if looper && looper_name
          looper.collect do |single|
            render(partl, self, new_locals.merge(looper_name => single))
          end.join
        else
          render(partl, self, new_locals)
        end
      else
        raise RuntimeError, "Could not find partial `#{name}' from namespace #{@namespace}", caller
      end
    end

    def render(view_package, context, locals)
      self.class.engine(view_package.first).render(view_package, context, locals.merge(:layout => @layout))
    end

    def insert_section(name)
      return [] unless @locals[:"unrendered_#{name}"].is_a?(Array)
      @locals[name.to_sym] = @locals.delete(:"unrendered_#{name}").collect do |section|
        render(section, self, @locals)
      end
      @locals[name.to_sym]
    end

    def method_missing(name, value=nil, *args)
      sign = if name.to_s =~ /^(.*)([\=\?])$/
        name = $1.to_sym
        $2
      else
        ''
      end

      return @locals.has_key?(name) || @locals.has_key?(:"unrendered_#{name}") if sign == '?'
      raise NoMethodError, "no variable or method `#{name}' for view #{self}", caller if @html == :rendering

      if sign == '='
        @locals[name] = value
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

  class Layout < Template
    class << self
      def get_layout(name, ext=nil)
        if file = Dir.glob("#{APP_ROOT}/app/views/layouts/#{name}.#{ext || '*'}")[0]
          return file, File.read(file)
        end
      end
    end

    def initialize(controller, name, namespace='/')
      @controller = controller
      @name = name
      @locals = {}
      @namespace = namespace
      # load view helper if present
      if layout_helper = Layout.get_layout(@name, 'rb')
        @html = :helper
        instance_eval(layout_helper.last)
        @html = :rendering
      end
      @layout = Layout.get_layout(@name)
    end

    def render!(content_for_layout)
      if @layout
        render(@layout, self, locals.merge(:content_for_layout => content_for_layout))
      else
        content_for_layout
      end
    end
  end

  class FormatResponder
    def format_proc=(value)
      @format_proc = value
    end

    def to_s
      @to_s ||= @format_proc.call.to_s
    end
    alias :to_str :to_s

    def bytesize
      to_s.bytesize
    end
    alias :size :bytesize
  end

  module Templater
    # Method: layout
    def layout(name)
      @layout_name = name
    end

    # Method: view
    # Inputs: optionally, name and locals
    # Output: a view object, and whenever a name is given, set the name. Default to :default view if none given.
    def view(name=nil, locals={})
      locals = {:layout => @layout_name}.merge(locals) if @layout_name
      @view ||= Template.new(self, name || :default, locals)
      @view.name = name if name
      # Set the namespace into the view as soon as we seem to be inside of the action code.
      @view.set_namespace(self.class.namespaces[caller[0].match(/`(.*?)'/)[1]]) if caller[0] =~ /[A-Z]+ /
      if block_given?
        yield @view
      end
      return @view
    end

    # Method: respond_to
    # Inputs: type, &block
    # Output: The cumulative best chosen format will be returned each time this is called, so
    #          when called to render, it will run the block associated with that format and
    #          the result of the block is the response. The content_type header is also set up.
    def respond_to(type, &block)
      @respond_to ||= FormatResponder.new

      (@response_formats ||= []) << type
      preferred_format = accepts.each {|a| break a if @response_formats.include?(a) }
      content_type preferred_format
      @respond_to.format_proc = block if type == preferred_format

      @respond_to
    end
  end
end

require 'cilantro/templater/bootstrap'
Application.send(:include, Cilantro::Templater) if ::Object.const_defined?(:Application)
