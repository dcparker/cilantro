module Cilantro
  ########################################################################
  # Module: Cilantro::Controller
  # Provides Controller methods
  #
  # To generate rich pages, see: <Cilantro::Templater>
  module Controller
    include Sinatra::Helpers

    def self.included(base)
      base.extend ClassMethods
      
      def CilantroApplication.scopes
        @scopes ||= {}
      end
    end

    # Section: Class Methods
    module ClassMethods
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
      def scope(s=nil)
        if block_given?
          old_scope = @scope || '/'
          scope(old_scope + s)
          yield
          scope(old_scope)
        else
          if s.nil?
            @scope || ''
          else
            @scope = ('/'+s.to_s).gsub(/\/+$/,'').gsub(/\/\//, '/')
            # puts "Scope: #{@scope}"
          end
        end
      end

      # These were pulled right from sinatra/base.rb

      ########################################################################
      # Method: get(path, opts={}, &block)
      # Create a route matching the HTTP GET method and the given path regexp.
      def get(path, opts={}, &block)
        path = (scope + (path =~ /^\./ || path == '' ? '' : '/') + path).gsub(/\/\/+/,'/')
        # puts "Route: GET #{path}"
        CilantroApplication.scopes["GET #{path}"] = scope
        CilantroApplication.get(path, opts, &block)
      end
      def put(path, opts={}, &bk);    route 'PUT',    path, opts, &bk end
      def post(path, opts={}, &bk);   route 'POST',   path, opts, &bk end
      def delete(path, opts={}, &bk); route 'DELETE', path, opts, &bk end
      def head(path, opts={}, &bk);   route 'HEAD',   path, opts, &bk end

      def route(method, path, opts, &bk)
        path = (scope + (path =~ /^\./ || path == '' ? '' : '/') + path).gsub(/\/\/+/,'/')
        # puts "Route: #{method} #{path}"
        CilantroApplication.scopes["#{method} #{path}"] = scope
        CilantroApplication.send(:route, method, path, opts, &bk)
      end

      # Allows a helper method to be defined in the controller class.
      def helper_method(name, &block)
        CilantroApplication.send(:define_method, name, &block)
      end

      # accept reads the HTTP_ACCEPT header.
      CilantroApplication.send(:define_method, :accepts, Proc.new { @env['HTTP_ACCEPT'].to_s.split(',').map { |a| a.strip.split(';',2)[0] }.reverse })
      CilantroApplication.send(:define_method, :required_params, Proc.new { |*parms|
        not_present = parms.inject([]) do |a,(k,v)|
          a << k unless params.has_key?(k.to_s)
          a
        end
        throw :halt, [400, "Required POST params not present: #{not_present.join(', ')}\n"] unless not_present.empty?
      })

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
        CilantroApplication.error(*raised, &block)
      end

      def not_found(&block)
        error 404, &block
      end

      def before(&block)
        CilantroApplication.before(&block)
      end
    end
  end
end
