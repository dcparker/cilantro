gempath = "#{APP_ROOT}/gems"
if File.exists?(gempath)
  # Redirect standard output to the netherworld
  no_debug = '2>&1 >/dev/null'

  # Ensure each gem in gems/cache is installed
  Dir.glob("#{gempath}/cache/*.gem").each do |gem_name|
    gem_name = gem_name.match(/([^\/]+)\.gem/)[1]
    if !File.exists?("#{gempath}/gems/#{gem_name}")
      puts "Installing gem: #{gem_name}"
      j, name, version = *gem_name.match(/^(.*)-([\d\.]+)$/)
      puts `gem pristine --config-file gems/gemrc.txt #{name} -v#{version}`
      # LEAVE THIS HERE FOR LATER REFERENCE - These two commands unpack gems folders.
      # `mkdir -p #{gempath}/gems/#{gem_name} #{no_debug}`
      # `tar -Oxf #{gempath}/cache/#{gem_name}.gem data.tar.gz | tar -zx -C #{gempath}/gems/#{gem_name}/ #{no_debug}`
    end
  end
end
