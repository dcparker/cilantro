require 'dm-types'
include DataMapper::Types

migration 1, :create_listings do
  up do
    create_table :posts do
      column :id, Serial
      column :update, String
      column :created_at, DateTime
    end
  end

  down do
    drop_table :listings
  end
end
