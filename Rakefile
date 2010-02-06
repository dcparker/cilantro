require 'fileutils'

# Really need some way to determine what the ENV['RACK_ENV'] is "supposed" to be ..
# or should it be set globally so we know our context?
ENV['RACK_ENV'] = 'rake'

task :load_cilantro do
  if File.exists?('lib/cilantro.rb')
    require 'lib/cilantro'
  else
    raise "lib/cilantro.rb is missing!"
  end
end

namespace :env do
  task(:rake => [:load_cilantro]) { Cilantro.load_environment(:rake) }
  task(:development => [:load_cilantro]) { Cilantro.load_environment(:development) }
  task(:production => [:load_cilantro]) { Cilantro.load_environment(:production) }
end

task :production_db => [:load_cilantro] do
  Cilantro.database_config 'config/database.production.yml' if File.exists?('config/database.production.yml')
end

# Load any app level custom rakefile extensions from lib/tasks
tasks_path = File.join(File.dirname(__FILE__), "tasks")
rake_files = Dir["#{tasks_path}/*.rake"]
rake_files.each do |rake_file|
  begin
    load rake_file
  rescue LoadError
    warn "Could not load #{rake_file}"
  end
end

##############################################################################
# ADD YOUR CUSTOM TASKS IN /tasks
# NAME YOUR RAKE FILES file_name.rake
##############################################################################
