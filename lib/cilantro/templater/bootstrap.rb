module Cilantro
  class Template
    # Markdown
    autoload(:ErbMarkdown, 'cilantro/templater/markdown')
    register_markup(/\.md$/, :ErbMarkdown)

    # Erb
    autoload(:Erb, 'cilantro/templater/erb')
    register_markup(/\.erb$/, :Erb)

    # Haml
    autoload(:Haml, 'cilantro/templater/haml')
    register_markup(/\.haml$/, :Haml)

    # LAST, add the plain markup which will be the fallback.
    autoload(:Plain, 'cilantro/templater/plain')
    register_markup(/.*/, :Plain)
  end
end
