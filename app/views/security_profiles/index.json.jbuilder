json.array!(@security_profiles) do |security_profile|
  json.extract! security_profile, :id, :name, :description
  json.url security_profile_url(security_profile, format: :json)
end
