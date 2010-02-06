unless $LOADED_FEATURES.include?('lib/cilantro.rb') or $LOADED_FEATURES.include?('cilantro.rb')
  APP_ROOT = File.expand_path(File.dirname(__FILE__)+"/..") unless defined?(APP_ROOT)

  IRB.conf[:PROMPT_MODE] = :SIMPLE if ::Object.const_defined?(:IRB)

  require 'lib/cilantro/base'
end
