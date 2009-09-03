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

      def get(route, &block)
        Application.get(scope.gsub(/\/\/+/,'/') + route, &block)
      end
      def post(route, &block)
        Application.post(scope.gsub(/\/\/+/,'/') + route, &block)
      end
      def error(*raised, &block)
        Application.error(*raised, &block)
      end
    end
  end
end
