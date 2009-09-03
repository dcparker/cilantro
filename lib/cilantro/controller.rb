module Cilantro
  module Controller
    def self.included(base)
      base.extend Methods
    end

    module Methods
      def scope(s=nil)
        if block_given?
          old_scope = @scope
          scope(old_scope + s)
          yield
          scope(old_scope)
        else
          if s.nil?
            @scope || ''
          else
            s += '/' unless s =~ /\/$/
            @scope = s
          end
        end
      end

      # These were pulled right from sinatra/base.rb
      def get(path, opts={}, &block)
        path = (scope + path).gsub(/\/\/+/,'/')
        # puts "Route: GET #{path}"
        Application.get(path, opts, &block)
      end
      def put(path, opts={}, &bk);    route 'PUT',    path, opts, &bk end
      def post(path, opts={}, &bk);   route 'POST',   path, opts, &bk end
      def delete(path, opts={}, &bk); route 'DELETE', path, opts, &bk end
      def head(path, opts={}, &bk);   route 'HEAD',   path, opts, &bk end

      def route(method, path, opts, &bk)
        path = (scope + path).gsub(/\/\/+/,'/')
        # puts "Route: #{method} #{path}"
        Application.send(:route, method, path, opts, &bk)
      end
      def error(*raised, &block)
        Application.error(*raised, &block)
      end
      def not_found(&block)
        error 404, &block
      end
      def before(&block)
        Application.before(&block)
      end
    end
  end
end
