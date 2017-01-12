json.array!(@parent_orgs) do |parent_org|
  json.extract! parent_org, :id, :name, :code
  json.url parent_org_url(parent_org, format: :json)
end
