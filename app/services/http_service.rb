class HttpService

  def self.post_emails(url, xml)
    uri = URI.parse(url)
    request = Net::HTTP.new(uri.host, uri.port)
    request.use_ssl = true
    base64creds = Base64.strict_encode64(SECRETS.wd_xml_creds)
    res = request.post(uri.path, xml, {'Content-Type' => 'text/xml', 'Content-Length' => xml.length.to_s, 'Authorization' => "Basic #{base64creds}", "Connection" => "keep-alive" })
    res.body
  end
end
