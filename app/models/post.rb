class Post
  include DataMapper::Resource
  property :id, Serial
  property :update, String
  property :created_at, DateTime
end
