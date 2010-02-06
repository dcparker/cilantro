#!/for/textmate/recognition/ruby

# Read configuration, if there is any
require 'yaml'
$config = YAML.load_file("#{directory}/config/production.yml") rescue {}
ENV['RACK_ENV'] ||= ($config[:environment] || 'development').to_s
require 'lib/cilantro'

Cilantro.database_config $config[:database_config] if $config[:database_config]
Cilantro.load_environment
Cilantro.set_options(
  :run => Proc.new { false },
  :host => $config[:host] || '0.0.0.0',
  :port => $config[:port] || '5000'
)

run Application
