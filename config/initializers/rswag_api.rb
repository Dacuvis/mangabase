Rswag::Api.configure do |c|
  # Lokasi file swagger.yaml / swagger.json
  c.openapi_root = Rails.root.join("swagger").to_s
end
