require 'dm-types'
include DataMapper::Types

module SQL
  module Mysql
    def create_table_statement(quoted_table_name)
      "CREATE TABLE #{quoted_table_name}"
    end
  end
end

migration 1, :create_listings do
  up do
    create_table(:listings) do
      column(:id, Integer, :key => true)
      column(:name, String)
      column(:address, String)
      column(:created_at, DateTime)
    end
  end

  down do
    drop_table(:listings)
  end
end
