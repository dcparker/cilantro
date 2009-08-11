class Listing
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :address, String
  property :created_at, DateTime
end
