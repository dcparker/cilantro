require File.dirname(__FILE__)+'/cilantro/system/mysql_fix' if File.exists?(File.dirname(__FILE__)+'/cilantro/system/mysql_fix')

module Cilantro
  class << self
    attr_accessor :auto_reload

    def load_environment(env=nil)
      const_set("RACK_ENV", env) if env
      ENV['RACK_ENV'] = RACK_ENV.to_s

      $: << APP_ROOT unless $:.include?(APP_ROOT)
      $: << APP_ROOT+'/lib' unless $:.include?(APP_ROOT+'/lib')

      require 'rubygems'
      require 'rubygems/custom_require'

      # First we'll sandbox rubygems if it looks like a sandbox is being used:
      require 'cilantro/system/gem_sandbox'

      # Beginning with RACK_ENV, we determine which pieces of the app's environment need to be loaded.
        # If in development or production mode, we need to load up Sinatra:
        puts @something_changed ? "Reloading the app..." : "Loading Cilantro environment #{RACK_ENV.inspect}" unless RACK_ENV == :test
        if RACK_ENV == :development || RACK_ENV == :production || RACK_ENV == :test
          require File.dirname(__FILE__)+'/cilantro/auto_reload' if auto_reload
          require 'cilantro/sinatra'
          # @base_constants = ::Object.constants - ['Application']
          # @base_required = $LOADED_FEATURES.dup - ['cilantro/sinatra.rb']
          set_options(
            :static => true,
            :public => 'public',
            :server => (auto_reload ? 'thin_cilantro_proxy' : 'thin'),
            :logging => true,
            :raise_errors => (RACK_ENV == :production),
            :show_exceptions => !(RACK_ENV == :production),
            :environment => RACK_ENV
          )
        else
          # @base_constants = ::Object.constants
          # @base_required = $LOADED_FEATURES.dup
        end
      # ****

      # Load the app pre-environment
      require 'config/init'

      # Lastly, we'll load the app files themselves: lib, models, then controllers
        # lib/*.rb - those already loaded won't be reloaded.
        Dir.glob("lib/*.rb").each {|file| require file.split(/\//).last }
        # app/models/*.rb
        Dir.glob("app/models/*.rb").each {|file| require file}
        # app/controllers/*.rb UNLESS in irb
        Dir.glob("app/controllers/*.rb").each {|file| require file} if RACK_ENV == :development || RACK_ENV == :production || RACK_ENV == :test

      return true
    end

    def reload_environment
      # added_constants = ::Object.constants - @base_constants
      # added_constants.each do |const|
      #   begin
      #     ::Object.send(:remove_const, const.to_sym)
      #   rescue NameError
      #   end
      # end
      # $LOADED_FEATURES.replace(@base_required)
      load_environment
      set_options @server_options
    end

    def set_options(options)
      @server_options ||= {}
      @server_options.merge!(options)
      Cilantro.app.set @server_options
    end

    def app
      defined?(::Application) ? ::Application : nil
    end

    def config
      @config ||= ((YAML.load_file("#{APP_ROOT}/config/cilantro.yml") if File.exists?("#{APP_ROOT}/config/cilantro.yml")) || {})
    end

    def database_config(file=nil)
      if file
        @database_config_file = file
      else
        @database_config_file ||= "#{APP_ROOT}/config/database.yml"
        if File.exists?(@database_config_file)
          cfg = (YAML.load_file(@database_config_file) || {})
          cfg = cfg[:database] if cfg[:database].is_a?(Hash)
        end

        unless cfg
          warn "Cannot set up the database: Config information (#{@database_config_file}) missing!"
          exit
        end

        cfg
      end
    end

    def setup_database
      DataMapper.setup(:default, Cilantro.database_config)
    end

    def report_error(error)
      # Make the magic happen!
      # (jabber me when there's an error loading an app)
      if config[:notify]
        warn "\nNotifying #{config[:notify]} of the error."
        require 'rubygems'
        require 'xmpp4r'
        client = Jabber::Client.new(Jabber::JID.new("#{config[:username]}/cilantro"))
        client.connect('talk.google.com', '5222')
        client.auth(config[:password])
        client.send(Jabber::Presence.new.set_type(:available))
        msg = Jabber::Message.new(config[:notify], "#{error.inspect}\n#{error.backtrace.join("\n")}")
        msg.type = :chat
        client.send(msg)
        client.close
      else
        warn "\n! Nobody configured to notify via jabber."
      end
    end
  end

  ########################################################################
  # Module: Cilantro::Controller
  # Provides Controller methods
  #
  # To generate rich pages, see: <Cilantro::Templater>
  module Controller
    # include Sinatra::Helpers

    attr_reader :application
    
    ########################################################################
    # Method: scope(string)
    # Define scope for the next routes. The scope will be prepended to routes.
    # The scope is also saved for each route and used to find views for that
    # route.
    #
    # Example: 
    # > scope = '/people'
    # > get 'new' do 
    # >   template :new
    # > end
    # > # GET /people/new
    # > #  -> action is run, template is found in: /views/people/new.haml
    def scope(new_scope=nil,name=nil,&block)
      raise ArgumentError, "Scope must be a string, a symbol, or a hash with string values." if !new_scope.nil? && !(new_scope.is_a?(String) || new_scope.is_a?(Symbol) || new_scope.is_a?(Hash))
      @scope ||= '/'
      if new_scope.is_a?(Hash)
        new_scope.each do |name,new_scope|
          block_given? ? scope(new_scope,name) { block.call } : scope(new_scope,name)
        end
      else
        # Here we have just one scope and *possibly* a name to save for the first route registered with this scope.
        # Sanitize new scope to NOT end with a slash OR begin with a slash.
        @next_route_name = new_scope if new_scope.is_a?(Symbol)
        new_scope = new_scope.to_s.gsub(/(^\/|\/$)/,'') if new_scope
        @next_route_name = name if name
        # Join scope to previous scope by a slash.
        if block_given?
          old_scope = @scope
          @scope = @scope.gsub(/\/$/,'')+'/'+new_scope
          yield
          @scope = old_scope
        else
          if new_scope.nil?
            @scope
          else
            @scope = @scope.gsub(/\/$/,'')+'/'+new_scope
          end
        end
      end
    end
    alias :path :scope

    def get(path='', opts={}, &bk);    route 'GET',    path, opts, &bk end
    def put(path='', opts={}, &bk);    route 'PUT',    path, opts, &bk end
    def post(path='', opts={}, &bk);   route 'POST',   path, opts, &bk end
    def delete(path='', opts={}, &bk); route 'DELETE', path, opts, &bk end
    def head(path='', opts={}, &bk);   route 'HEAD',   path, opts, &bk end

    # Allows a helper method to be defined in the controller class.
    def helper_method(name, &block)
      application.send(:define_method, name, &block)
    end

    # # accept reads the HTTP_ACCEPT header.
    # Application.send(:define_method, :accepts, Proc.new { @env['HTTP_ACCEPT'].to_s.split(',').map { |a| a.strip.split(';',2)[0] }.reverse })
    # Application.send(:define_method, :required_params, Proc.new { |*parms|
    #   not_present = parms.inject([]) do |a,(k,v)|
    #     a << k unless params.has_key?(k.to_s)
    #     a
    #   end
    #   throw :halt, [400, "Required POST params not present: #{not_present.join(', ')}\n"] unless not_present.empty?
    # })

    ########################################################################
    # Method: error(*errors, &block)
    # Define the proper response for errors.
    #
    # Expected Output: HTTP message body (String).
    #
    # Example: 
    # > error do
    # >   Cilantro.report_error(env['sinatra.error'])   # this could jabber the error to the admin
    # >   return 'Something went wrong!'
    # > end
    def error(*raised, &block)
      application.error(*raised, &block)
    end

    def not_found(&block)
      error 404, &block
    end

    def setup(&block)
      raise ArgumentError, "Setup must include a code block" unless block_given?
      # new_block = lambda {
      #   block.call
      # }
      # application.scoped_filters << [scope, block]
    end

    def before(&block)
      application.before(&block)
    end

    def helper(name, &block)
      puts "Defining helper #{self.name.to_s + '_' + name.to_s}"
      application.send(:define_method, self.name.to_s + '_' + name.to_s, &block)
    end

    private
      def route(method, in_path, opts, &bk)
        if in_path.is_a?(Hash)
          in_path.inject([]) do |rts,(name,path)|
            path = path_with_scope(path)
            # puts "Route: #{method} #{path[0]}"
            # Save the scope with this route
            application.scopes["#{method} #{path[0]}"] = [self, scope]
            # Register the path with Sinatra's routing engine
            rt = application.send(method.downcase, path[0], opts, &bk)
            rt[1].replace(path[1])
            # Link up the name to the compiled route regexp
            application.route_names[name.to_sym] = [rt[0], rt[1]]
            # puts "\tnamed :#{name}  -- #{rt[0]}"
            rts << rt
          end
        else
          path = path_with_scope(in_path)
          # puts "Route: #{method} #{path[0]}"
          # Save the scope with this route
          application.scopes["#{method} #{path[0]}"] = [self, scope]
          # Register the path with Sinatra's routing engine
          rt = application.send(method.downcase, path[0], opts, &bk)
          rt[1].replace(path[1])
          # Link up any awaiting name to the compiled route regexp
          if in_path == '' && @next_route_name
            application.route_names[@next_route_name.to_sym] = [rt[0], rt[1]]
            # puts "\tnamed :#{@next_route_name}  -- #{rt[0]}"
            @next_route_name = nil
          end
          return rt
        end
      end

      def path_with_scope(path)
        if path.is_a?(Regexp)
          # Scope should be already sanitized to NOT end with a slash.
          # Path should NOT be sanitized since it's a Regexp.
          # Scope + Path should be joined with a slash IF the path regexp does not begin with a '.'
          scrx, needs = application.send(:compile, scope)
          [Regexp.new(scrx.source.sub(/^\^/,'').sub(/\$$/,'') + path.source.sub(/^\^/,'').sub(/\$$/,'')), needs]
        else
          # Scope should be already sanitized to NOT end with a slash.
          # Path should be sanitized to NOT begin with a slash, and OPTIONALLY end with a slash.
          # Scope + Path should be joined with a slash IF the path string does not begin with a '.'
          # (scope + (path =~ /^\./ || path == '' ? '' : '/') + path).gsub(/\/\/+/,'/')
          application.send(:compile, scope + path.gsub(/^\//,''))
        end
      end
  end


  ########################################################################
  # Module: Cilantro::Application
  # Sets up the behavior of a Cilantro application.
  # Mainly this is included into ::Application < Sinatra::Base in sinatra.rb
  module Application
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        def method_missing(method_name, *args)
          # Try the helper methods for the current controller.
          send(controller.name.to_s + '_' + method_name.to_s, *args) rescue super
        end
      end
    end

    # Generates a url from routes.
    # Pass a hash of values (or an object that responds to the respective methods)
    # for named url values, or pass them in order as simple arguments.
    # Regexp routes will work too, as long as you pass in arguments for all
    # non-named parenthesis sections as well, and there are no other regexp special
    # characters present.
    def url(name, *args)
      options = args.last.is_a?(String) || args.last.is_a?(Numeric) ? nil : args.pop
      match, needs = self.class.route_names[name.to_sym]
      needs = needs.dup
      match = match.source.sub(/^\^/,'').sub(/\$$/,'')
      while match.gsub!(/\([^()]+\)/) { |m|
          # puts "M: #{m}"
          if m == '([^/?&#]+)'
            key = needs.shift
            # puts "Needs: #{key}"
            if options.is_a?(Hash)
              # puts "Hash value"
              options[key.to_sym] || options[key.to_s] || args.shift
            else
              if options.respond_to?(key)
                # puts "Getting value from object"
                options.send(key)
              else
                # puts "Shifting value"
                args.shift
              end
            end
          elsif m =~ /^\(\?[^\:]*\:(.*)\)$/
            # puts "matched #{m}"
            m.match(/^\(\?[^\:]*\:(.*)\)$/)[1]
          else
            raise "Could not generate route :#{name} for #{options.inspect}: need #{args.join(', ')}." if args.empty?
            args.shift
          end
        }
      end
      match.gsub(/\\(.)/,'\\1') # unescapes escaped characters
    end

    def scope
      (0..caller.length).each do |i|
        next unless caller[i] =~ /[A-Z]+ /
        @scope = self.class.scopes[caller[i].match(/`(.*?)'/)[1]]
      end unless @scope
      @scope[1] if @scope
    end

    def controller
      scope
      @scope[0] if @scope
    end

    module ClassMethods
      def scopes
        @scopes ||= {}
      end
      def route_names
        @route_names ||= {}
      end
      def scoped_filters
        @scoped_filters ||= []
      end

      def inherited(base)
        base.send(:extend, Cilantro::Controller)
        base.instance_variable_set(:@application, self)
      end
    end
  end
end