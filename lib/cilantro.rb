module Renderer
  def magic(view_name, options={})
    content_for_layout = view_name.is_a?(String) ? view_name : haml(File.read("app/views/#{view_name}.haml"))
    if options[:layout] == false
      content_for_layout
    else
      options[:layout] ||= :default
      haml File.read("app/views/layouts/#{options[:layout]}.haml"), :locals => {:content_for_layout => content_for_layout}
    end
  end

  def partial(partial_name)
    haml(File.read("app/views/_#{partial_name}.haml"))
  end
end
include Renderer


#--
# Copyright (C)2009 Tony Arcieri
# You can redistribute this under the terms of the MIT license
# See file LICENSE for details
#++
module RequireAll
  # A wonderfully simple way to load your code.
  #
  # The easiest way to use require_all is to just point it at a directory
  # containing a bunch of .rb files.  These files can be nested under 
  # subdirectories as well:
  #
  #  require_all 'lib'
  #
  # This will find all the .rb files under the lib directory and load them.
  # The proper order to load them in will be determined automatically.
  #
  # If the dependencies between the matched files are unresolvable, it will 
  # throw the first unresolvable NameError.
  #
  # You can also give it a glob, which will enumerate all the matching files: 
  #
  #  require_all 'lib/**/*.rb'
  #
  # It will also accept an array of files:
  #
  #  require_all Dir.glob("blah/**/*.rb").reject { |f| stupid_file(f) }
  # 
  # Or if you want, just list the files directly as arguments:
  #
  #  require_all 'lib/a.rb', 'lib/b.rb', 'lib/c.rb', 'lib/d.rb'
  #
  def require_all(*args)
    # Handle passing an array as an argument
    args = args.flatten
    
    if args.size > 1
      # If we got a list, those be are files!
      files = args
    else
      arg = args.first
      begin
        # Try assuming we're doing plain ol' require compat
        stat = File.stat(arg)
        
        if stat.file?
          files = [arg]
        elsif stat.directory?
          files = Dir.glob "#{arg}/**/*.rb"
        else
          raise ArgumentError, "#{arg} isn't a file or directory"
        end
      rescue Errno::ENOENT
        # If the stat failed, maybe we have a glob!
        files = Dir.glob arg
        
        # If we ain't got no files, the glob failed
        raise LoadError, "no such file to load -- #{arg}" if files.empty?
      end
    end
    
    files.map! { |file| File.expand_path file }
            
    begin
      failed = []
      first_name_error = nil
      
      # Attempt to load each file, rescuing which ones raise NameError for
      # undefined constants.  Keep trying to successively reload files that 
      # previously caused NameErrors until they've all been loaded or no new
      # files can be loaded, indicating unresolvable dependencies.
      files.each do |file|
        begin
          require file
        rescue NameError => ex
          failed << file
          first_name_error ||= ex
        rescue ArgumentError => ex
          # Work around ActiveSuport freaking out... *sigh*
          #
          # ActiveSupport sometimes throws these exceptions and I really
          # have no idea why.  Code loading will work successfully if these
          # exceptions are swallowed, although I've run into strange 
          # nondeterministic behaviors with constants mysteriously vanishing.
          # I've gone spelunking through dependencies.rb looking for what 
          # exactly is going on, but all I ended up doing was making my eyes 
          # bleed.
          #
          # FIXME: If you can understand ActiveSupport's dependencies.rb 
          # better than I do I would *love* to find a better solution
          raise unless ex.message["is not missing constant"]
          
          STDERR.puts "Warning: require_all swallowed ActiveSupport 'is not missing constant' error"
          STDERR.puts ex.backtrace[0..9]
        end
      end
      
      # If this pass didn't resolve any NameErrors, we've hit an unresolvable
      # dependency, so raise one of the exceptions we encountered.
      if failed.size == files.size
        raise first_name_error
      else
        files = failed
      end
    end until failed.empty?
    
    true
  end
end
include RequireAll


# This is a fix, at least for the linode server install of mysql
module SQL
  module Mysql
    def create_table_statement(quoted_table_name)
      "CREATE TABLE #{quoted_table_name}"
    end
  end
end


module Cilantro
  DATABASE_CFG = 'config/database.yml'

  class << self
    def config
      @config ||= ((YAML.load_file('config/cilantro.yml') if File.exists?('config/cilantro.yml')) || {})
    end

    def database_config
      if File.exists?('config/linode.yml')
        return YAML.load_file('config/linode.yml')[:database]
      end
      if File.exists?(DATABASE_CFG)
        return YAML.load_file(DATABASE_CFG)
      else
        warn "Cannot set up the database: config/database.yml missing!"
        exit
      end
    end

    def setup_database
      # warn if config does not have necessary values in it
      DataMapper.setup(:default, Cilantro.database_config)
    end

    def report_error(error)
      # Make the magic happen!
      # (jabber me when there's an error loading an app)
      if config[:notify]
        require 'rubygems'
        require 'xmpp4r'
        client = Jabber::Client.new(Jabber::JID.new("#{config[:username]}/cilantro"))
        client.connect('talk.google.com', '5222')
        client.auth(config[:password])
        client.send(Jabber::Presence.new.set_type(:available))
        msg = Jabber::Message.new(config[:notify], "#{error.inspect}\n#{error.backtrace.join("\n")}")
        msg.type = :chat
        client.send(msg)
        client.close
      end
    end
  end
end
