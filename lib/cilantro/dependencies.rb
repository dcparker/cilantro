require 'rubygems'
require 'rubygems/custom_require'

module Cilantro
  class << self
    def gems
      @gems ||= {}
    end

    def add_gem(name, options)
      if gems[name]
        gems[name].merge!(options)
      else
        gems[name] = options
      end
      if env == :development
        open(".gems", 'w') do |f|
          gems.keys.sort.each do |name|
            options = gems[name]
            next if options[:only_env] == :development
            gem_def = name.dup
            gem_def << " --version '#{options[:version]}'" if options[:version]
            f << gem_def << "\n"
          end
        end if File.writable?('.gems')
      end
    end

    def install_missing_gems
      gempath = "#{APP_ROOT}/gems"
      if File.exists?(gempath)
        # Redirect standard output to the netherworld
        no_debug = '2>&1 >/dev/null'

        all_gems = ""
        # Ensure each gem in gems/cache is installed
        Dir.glob("#{gempath}/cache/*.gem").each do |gem_name|
          gem_name = gem_name.match(/([^\/]+)\.gem/)[1]
          j, name, version = *gem_name.match(/^(.*)-([\d\.]+)$/)
          Cilantro.add_gem(name, :version => version)
          if !File.exists?("#{gempath}/gems/#{gem_name}")
            puts "Installing gem: #{gem_name}"
            pristined = `gem pristine --config-file gems/gemrc.yml -v #{version} #{name}`
            if $?.success?
              puts pristined
            else
              direct = `gem install -i gems --no-rdoc --no-ri gems/cache/#{gem_name}.gem`
              if $?.success?
                puts direct
              else
                puts `gem install -i gems --no-rdoc --no-ri -v #{version} #{name}`
              end
            end
            # LEAVE THIS HERE FOR LATER REFERENCE - These two commands unpack gems folders. Might be quicker than gem pristine? (but doesn't compile any gem binary libraries)
            # `mkdir -p #{gempath}/gems/#{gem_name} #{no_debug}`
            # `tar -Oxf #{gempath}/cache/#{gem_name}.gem data.tar.gz | tar -zx -C #{gempath}/gems/#{gem_name}/ #{no_debug}`
          end
        end
      end
    end
  end
end

# 2. Each dependency should:
#   a) Require the dependency.
#   b) If not installed and is possible to install, INSTALL IT.
#   c) If in development, and dependency is needed in production, write itself to .gems.
module Kernel
  def dependency(name, options={})
    options[:only_env] = options[:env]
    options[:env] = ENV['RACK_ENV'] unless options[:env]
    if options[:env] == ENV['RACK_ENV']
      begin
        require name
      rescue LoadError => e
        if File.directory?("#{APP_ROOT}/gems") && File.writable?("#{APP_ROOT}/gems")
          if e.respond_to?(:name) && e.respond_to?(:version_requirement)
            puts "Installing #{e.name}#{" -v \""+e.version_requirement.to_s+'"' if e.version_requirement}..."
            puts `gem install -i gems --no-rdoc --no-ri #{"-v \""+e.version_requirement.to_s+'"' if e.version_requirement} #{e.name}`
          else
            puts "Installing #{options[:gem] || name}#{" -v "+options[:version] if options[:version]}..."
            puts `gem install -i gems --no-rdoc --no-ri #{"-v "+options[:version] if options[:version]} #{options[:gem] || name}`
          end
          Gem.use_paths("#{APP_ROOT}/gems", ["#{APP_ROOT}/gems"])
          begin
            require name
          rescue LoadError
            puts "(didn't work installing `#{name}' in path: #{Dir.pwd})"
            puts "Load Path: #{$:.join("\n")}"
            puts "Gem Path: #{Gem.path.inspect}"
          end
        else
          raise
        end
      end
    end
    Cilantro.add_gem(options[:gem] || name, options)
  end
end

# 1. Sandbox Rubygems
APP_ROOT = File.expand_path(Dir.pwd) unless defined?(APP_ROOT)

if File.directory?("#{APP_ROOT}/gems")
  # Oh but first, go ahead and install any missing gems (PLEASE, only include gems/specifications and gems/cache in your git repo)
    Cilantro.install_missing_gems if File.writable?("#{APP_ROOT}/gems")
  Gem.use_paths("#{APP_ROOT}/gems", ["#{APP_ROOT}/gems"])
end
