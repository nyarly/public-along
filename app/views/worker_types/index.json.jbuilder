json.array!(@worker_types) do |worker_type|
  json.extract! worker_type, :id, :name, :code, :kind, :status
  json.url worker_type_url(worker_type, format: :json)
end
