unless $LOADED_FEATURES.include?('lib/cilantro.rb') or $LOADED_FEATURES.include?('cilantro.rb')
  APP_ROOT = File.expand_path(File.dirname(__FILE__)+"/..") unless defined?(APP_ROOT)

  RACK_ENV = (ENV['RACK_ENV'] && ENV['RACK_ENV'].to_sym) || :irb unless ::Object.const_defined?(:RACK_ENV)
  IRB.conf[:PROMPT_MODE] = :SIMPLE if ::Object.const_defined?(:IRB)

  require File.dirname(__FILE__)+'/cilantro/system/mysql_fix'

  module Cilantro
    class << self
      attr_accessor :auto_reload

      def load_environment(env=nil)
        const_set("RACK_ENV", env) if env
        ENV['RACK_ENV'] = RACK_ENV.to_s

        $: << APP_ROOT+'/lib' unless $:.include?(APP_ROOT+'/lib')

        require 'rubygems'
        require 'rubygems/custom_require'

        # First we'll sandbox rubygems if it looks like a sandbox is being used:
        require 'cilantro/system/gem_sandbox'

        # Beginning with RACK_ENV, we determine which pieces of the app's environment need to be loaded.
          # If in development or production mode, we need to load up Sinatra:
          puts @something_changed ? "Reloading the app..." : "Loading Cilantro environment #{RACK_ENV.inspect}"
          if RACK_ENV == :development || RACK_ENV == :production || RACK_ENV == :test
            require File.dirname(__FILE__)+'/cilantro/auto_reload' if auto_reload
            require 'cilantro/sinatra'
            @base_constants = ::Object.constants - ['CilantroApplication']
            @base_required = $LOADED_FEATURES.dup - ['cilantro/sinatra.rb']
            require 'cilantro/controller'
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
            @base_constants = ::Object.constants
            @base_required = $LOADED_FEATURES.dup
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
        added_constants = ::Object.constants - @base_constants
        added_constants.each do |const|
          begin
            ::Object.send(:remove_const, const.to_sym)
          rescue NameError
          end
        end
        $LOADED_FEATURES.replace(@base_required)
        load_environment
        set_options @server_options
      end

      def set_options(options)
        @server_options ||= {}
        @server_options.merge!(options)
        Cilantro.app.set @server_options
      end

      def app
        defined?(CilantroApplication) ? ::CilantroApplication : nil
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
  end
end
