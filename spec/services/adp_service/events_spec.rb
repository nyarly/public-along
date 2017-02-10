
require 'rails_helper'

describe AdpService::Events, type: :service do
  let(:url)         { "https://accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:uri)         { double(URI) }
  let(:host)        { "accounts.adp.com" }
  let(:port)        { 443 }
  let(:request_uri) { "/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:http)        { double(Net::HTTP) }
  let(:response)    { double(Net::HTTPResponse) }
  let(:header_hash) { {"server"=>["Apache-Coyote/1.1"], "adp-correlationid"=>["ac5c8427-d7df-4a36-9c1c-ed9a9405e58f"], "content-language"=>["en-US"], "adp-msg-msgid"=>["0x_414d51205554494e464f4251362020206f3e8b5866814928"], "etag"=>["W/\"298-3FGDAYibwmNEuawCuC+BEg\""], "x-upstream"=>["10.136.1.43:4110"], "strict-transport-security"=>["max-age=31536000"], "content-type"=>["application/json;charset=utf-8"], "content-length"=>["664"], "date"=>["Fri, 10 Feb 2017 00:57:40 GMT"], "connection"=>["close"]} }
  let(:json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_event.json") }
  let(:hire_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_hire_event.json") }
  let(:contract_hire_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_contract_hire_event.json") }

  before :each do
    allow(uri).to receive(:host).and_return(host)
    allow(uri).to receive(:port).and_return(port)
    allow(uri).to receive(:request_uri).and_return(request_uri)
    allow(http).to receive(:cert=)
    allow(http).to receive(:key=)
    allow(OpenSSL::X509::Certificate).to receive(:new)
    allow(OpenSSL::PKey::RSA).to receive(:new)

    allow(URI).to receive(:parse).with(url).and_return(uri)
    allow(Net::HTTP).to receive(:new).with(host, port).and_return(http).at_least(:once)
    allow(http).to receive(:read_timeout=).with(200).at_least(:once)
    allow(http).to receive(:use_ssl=).with(true).at_least(:once)
    allow(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER).at_least(:once)
    allow(http).to receive(:post).with(
      request_uri,
      '',
      { "Accept"=>"application/json",
        "Authorization"=>"Basic #{SECRETS.adp_creds}",
      }).and_return(response)
    expect(response).to receive(:body).once.and_return('{"access_token": "7890f85c-43ef-4ebc-acb7-f98f2c0581d0"}')
  end

  it "should get a bearer token from ADP" do
    expect(AdpService::Events.new.token).to eq("7890f85c-43ef-4ebc-acb7-f98f2c0581d0")
  end

  describe "events" do
    let!(:worker_type_1) { FactoryGirl.create(:worker_type, name: "Contractor", code: "CONT") }
    let!(:worker_type_2) { FactoryGirl.create(:worker_type, name: "Regular Full-Time", code: "OLFR") }
    let(:ads) { double(ActiveDirectoryService) }

    before :each do
      allow(URI).to receive(:parse).with("https://api.adp.com/core/v1/event-notification-messages").and_return(uri)
      allow(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should create AdpEvent with correct values" do
      expect(response).to receive(:body).and_return(json)
      expect(response).to receive(:to_hash).and_return(header_hash)

      adp = AdpService::Events.new
      adp.token = "a-token-value"

      expect{
        adp.events
      }.to change{AdpEvent.count}.from(0).to(1)
    end

    it "should create Employee if new hire event" do
      expect(response).to receive(:body).and_return(hire_json)
      expect(response).to receive(:to_hash).and_return(header_hash)
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:create_disabled_account)

      adp = AdpService::Events.new
      adp.token = "a-token-value"

      expect{
        adp.events
      }.to change{Employee.count}.from(0).to(1)
    end

    it "should have worker end date if contract hire event" do
      expect(response).to receive(:body).and_return(contract_hire_json)
      expect(response).to receive(:to_hash).and_return(header_hash)
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:create_disabled_account)

      adp = AdpService::Events.new
      adp.token = "a-token-value"

      expect{
        adp.events
      }.to change{Employee.count}.from(0).to(1)
      expect(Employee.last.contract_end_date).to_not be_nil
    end
  end
end
