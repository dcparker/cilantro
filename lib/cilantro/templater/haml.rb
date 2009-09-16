require 'haml'

module Cilantro
  class Template
    class Haml
      def initialize(options={})
        @options = options
      end

      def render(template, context, locals)
        # Haml is pretty simple!
        ::Haml::Engine.new(template).render(context, locals)
      end
    end
  end
end
