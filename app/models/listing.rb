class Listing
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :address, String
  property :created_at, DateTime
  auto_migrate! unless storage_exists?
end
