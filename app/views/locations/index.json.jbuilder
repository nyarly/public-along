json.array!(@locations) do |location|
  json.extract! location, :id, :name, :kind, :country
  json.url location_url(location, format: :json)
end
