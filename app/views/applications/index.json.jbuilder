json.array!(@applications) do |application|
  json.extract! application, :id, :name, :description, :ad_security_group, :dependency, :instructions
  json.url application_url(application, format: :json)
end
