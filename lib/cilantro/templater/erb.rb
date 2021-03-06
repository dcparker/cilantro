require 'erb'

module Cilantro
  class Template
    class Erb < Plain
      def render(view, context, locals)
        erb_text = render_upstream(view, context, locals)
        # Set up a proxy object for the binding
        new_context = Object.new
        new_context.send(:instance_variable_set, :@context, context)
        new_context.send(:instance_variable_set, :@locals, locals)
        new_context.instance_eval("
          def method_missing(m, *args)
            @locals.has_key?(m) ? @locals[m] : @context.send(m, *args)
          rescue NoMethodError
            nil
          end
        ")
        context = new_context.instance_eval("binding")
        # Now, use the new context (binding) for rendering
        ::ERB.new(erb_text).result(context)
      end
    end
  end
end
