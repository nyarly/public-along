module AdpService
  class Base
    attr_accessor :token

    def initialize
      @token ||= get_bearer_token
    end

    # These are some utility methods to help navigate the API

    def meta
      str = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers/meta")
      json = JSON.parse(str)
      puts JSON.pretty_generate(json)
      json
    end

    def list(qty, pos)
      str = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers?$top=#{qty}&$skip=#{pos}&count=true")
      json = JSON.parse(str)
      puts JSON.pretty_generate(json)
      emps = json["workers"]
      puts actual_count: emps.count
      count = json["meta"]["totalNumber"]
      puts worker_count: count
      json
    end

    def worker(uri)
      str = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers#{uri}")
      json = JSON.parse(str)
      puts JSON.pretty_generate(json)
      json
    end

    def url(url)
      str = get_json_str("#{url}")
      json = JSON.parse(str)
      puts JSON.pretty_generate(json)
      json
    end

    private

    def get_bearer_token
      set_http("https://#{SECRETS.adp_token_domain}/auth/oauth/v2/token?grant_type=client_credentials")
      res = @http.post(@uri.request_uri,'', {'Accept' => 'application/json', 'Authorization' => "Basic #{SECRETS.adp_creds}"})

      JSON.parse(res.body)["access_token"]
    end

    def set_http(url)
      @uri = URI.parse(url)
      @http = Net::HTTP.new(@uri.host, @uri.port)
      @http.read_timeout = 200
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      pem = File.read(SECRETS.adp_pem_path)
      key = File.read(SECRETS.adp_key_path)
      @http.cert = OpenSSL::X509::Certificate.new(pem)
      @http.key = OpenSSL::PKey::RSA.new(key)
    end

    def get_json_str(url)
      set_http(url)
      res = @http.get(@uri.request_uri, {'Accept' => 'application/json', 'Authorization' => "Bearer #{@token}"})
      res.body
    end
  end
end
