dependency 'bluecloth'

module Cilantro
  class Template
    class Markdown < Plain
      def render(view, context, locals)
        markdown_text = render_upstream(view, context, locals)
        # Now render the Markdown
        BlueCloth.new(markdown_text).to_html
      end
    end
  end
end
