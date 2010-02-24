module Cilantro
  class Template
    # Markdown
    autoload(:Markdown, 'cilantro/templater/markdown')
    register_markup(/\.markdown$/, :Markdown)
    register_markup(/\.md$/, :Markdown)

    # Erb
    autoload(:Erb, 'cilantro/templater/erb')
    register_markup(/\.erb$/, :Erb)

    # Haml
    autoload(:Haml, 'cilantro/templater/haml')
    register_markup(/\.haml$/, :Haml)

    # LASTLY, add the plaintext markup which will be the fallback.
    autoload(:Plain, 'cilantro/templater/plain')
    register_markup(/.*/, :Plain)
  end
end
