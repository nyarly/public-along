json.array!(@machine_bundles) do |machine_bundle|
  json.extract! machine_bundle, :id, :name, :description
  json.url machine_bundle_url(machine_bundle, format: :json)
end
