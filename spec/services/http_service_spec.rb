require 'rails_helper'

describe HttpService, type: :service do
  describe "post_emails" do
    let(:url) { "https://www.example.com/" }
    let(:xml) {
      "<?xml version=\"1.0\"?>\n<root>\n  <individual>\n    <identifier>12100401</identifier>\n    <email>jlebowski@opentable.com</email>\n  </individual>\n  <individual>\n    <identifier>12101234</identifier>\n    <email>mlebowski@opentable.com</email>\n  </individual>\n</root>\n"
    }
    let(:uri) { double(URI) }
    let(:host) { "https://www.example.com" }
    let(:port) { 443 }
    let(:path) { "/" }
    let(:creds) { "dXNlckB0ZXN0aW5nOnBhc3N3b3Jk" }
    let(:http) { double(Net::HTTP) }
    let(:response) { double(Net::HTTPResponse) }

    it "should post emails to the provided url with the provided xml" do
      allow(uri).to receive(:host).and_return(host)
      allow(uri).to receive(:port).and_return(port)
      allow(uri).to receive(:path).and_return(path)

      expect(URI).to receive(:parse).with(url).and_return(uri)
      expect(Net::HTTP).to receive(:new).with(host, port).and_return(http)
      expect(http).to receive(:use_ssl=).with(true)
      expect(Base64).to receive(:strict_encode64).with(SECRETS.wd_xml_creds).and_return(creds)
      expect(http).to receive(:post).with(
        path,
        xml,
        { "Content-Type"=>"text/xml",
          "Content-Length"=>"261",
          "Authorization"=>"Basic #{creds}",
          "Connection"=>"keep-alive"
        }).and_return(response)
      allow(response).to receive(:body)

      HttpService.post_emails(url, xml)
    end
  end
end
