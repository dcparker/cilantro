dependency 'bluecloth'

module Cilantro
  class Template
    class ErbMarkdown < Erb
      alias :render_erb :render

      def render(template, context, locals)
        markdown_text = render_upstream(template, context, locals)
        # Now render the Markdown
        BlueCloth.new(markdown_text).to_html
      end
    end
  end
end
