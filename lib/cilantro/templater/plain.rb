module Cilantro
  class Template
    class Plain
      def initialize(options={})
        # Don't even need this for plaintext, but this initialize is for the child classes.
        @options = options
      end

      # This is just for the child classes - it will never be used in the context of Plain itself.
      def render_upstream(template, context, locals)
        @options[:upstream].render(template, context, locals)
      end

      def render(template, context, locals)
        # Plain text renderer does not cascade up anymore, it is always the last stop!
        template.last
      end
    end
  end
end
