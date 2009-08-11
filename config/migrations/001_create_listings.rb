migration 1, :create_listings do
  up do
    create_table(:listings) do
      column(:id, Serial)
      column(:name, String)
      column(:address, String)
      column(:created_at, DateTime)
    end
  end

  down do
    drop_table(:listings)
  end
end
