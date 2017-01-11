class AdpService
  attr_accessor :token

  def initialize
    @token ||= get_bearer_token
  end

  def populate_job_titles
    str = get_json_str("https://api.adp.com/codelists/hr/v3/worker-management/job-titles/WFN/1")
    json = JSON.parse(str)
    titles = json["codeLists"].find { |l| l["codeListTitle"] == "job-titles"}["listItems"]
    JobTitle.update_all(status: "Inactive")
    titles.each do |t|
      code = t["codeValue"]
      name = t["shortName"].present? ? t["shortName"] : t["longName"]
      jt = JobTitle.find_or_create_by(code: code)
      jt.update_attributes({name: name, status: "Active"})
    end
  end

  def populate_locations
    str = get_json_str("https://api.adp.com/codelists/hr/v3/worker-management/locations/WFN/1")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    locs = json["codeLists"].find { |l| l["codeListTitle"] == "locations"}["listItems"]
    Location.update_all(status: "Inactive")
    locs.each do |l|
      code = l["codeValue"]
      name = l["shortName"].present? ? l["shortName"] : l["longName"]
      kind = name.include?("Office") ? "Office" : "Remote Location"
      loc = Location.find_or_create_by(code: code)
      old_loc_co = Location.find_by(name: loc.name, status: "Inactive").country
      country = old_loc_co.present? ? old_loc_co : "US"
      loc.update_attributes({name: name, country: country, kind: kind, status: "Active"})
    end
  end

  private

  def get_bearer_token
    set_http("https://accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials")
    res = @http.post(@uri.request_uri,'', {'Accept' => 'application/json', 'Authorization' => "Basic #{SECRETS.adp_creds}"})
    JSON.parse(res.body)["access_token"]
  end

  def set_http(url)
    @uri = URI.parse(url)
    @http = Net::HTTP.new(@uri.host, @uri.port)
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    @http.cert = OpenSSL::X509::Certificate.new(SECRETS.adp_pem)
    @http.key = OpenSSL::PKey::RSA.new(SECRETS.adp_key)
  end

  def get_json_str(url)
    set_http(url)
    res = @http.get(@uri.request_uri, {'Accept' => 'application/json', 'Authorization' => "Bearer #{@token}"})
    res.body
  end
end
