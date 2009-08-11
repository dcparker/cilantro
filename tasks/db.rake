
require 'fileutils'

namespace :db do
  
  desc "Perform automigration"
  task :automigrate do
    ::DataMapper::AutoMigrator.auto_migrate
  end
  desc "Perform non destructive automigration"
  task :autoupgrade do
    ::DataMapper::AutoMigrator.auto_upgrade
  end

  namespace :migrate do
    task :load do
      gem 'dm-migrations'
      require 'migration_runner'
      FileList["config/migrations/*.rb"].each do |migration|
        load migration
      end
    end

    desc "Migrate up using migrations"
    task :up, :version, :needs => :load do |t, args|
      version = args[:version] || ENV['VERSION']
      migrate_up!(version)
    end
    desc "Migrate down using migrations"
    task :down, :version, :needs => :load do |t, args|
      version = args[:version] || ENV['VERSION']
      migrate_down!(version)
    end
  end

  desc "Migrate the database to the latest version"
  task :migrate => 'db:migrate:up'

  desc "Create the database"
  task :create do
    # config = DataMapper.config
    puts "Creating database '#{config[:database]}'"
    case config[:adapter]
    when 'postgres'
      `createdb -U #{config[:username]} #{config[:database]}`
    when 'mysql'
      `mysqladmin -u #{config[:username]} #{config[:password] ? "-p'#{config[:password]}'" : ''} create #{config[:database]}`
    when 'sqlite3'
      Rake::Task['rake:db:automigrate'].invoke
    else
      raise "Adapter #{config[:adapter]} not supported for creating databases yet."
    end
  end

  desc "Drop the database (postgres only)"
  task :drop do
    config = Merb::Orms::DataMapper.config
    puts "Droping database '#{config[:database]}'"
    case config[:adapter]
    when 'postgres'
      `dropdb -U #{config[:username]} #{config[:database]}`
    else
      raise "Adapter #{config[:adapter]} not supported for dropping databases yet.\ntry db:automigrate"
    end
  end

  desc "Drop the database, and migrate from scratch"
  task :reset => [:drop, :create, :migrate]
end

namespace :sessions do
  desc "Perform automigration for sessions"
  task :create => :merb_env do
    Merb::DataMapperSessionStore.auto_migrate!
  end

  desc "Clears sessions"
  task :clear => :merb_env do
    Merb::DataMapperSessionStore.all.destroy!
  end
end

