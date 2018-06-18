require 'rails_helper'

describe AdpService::CodeLists::SyncBusinessUnits, type: :service do
  let(:url)         { 'https://accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials' }
  let(:uri)         { double(URI) }
  let(:host)        { 'accounts.adp.com' }
  let(:port)        { 443 }
  let(:request_uri) { '/auth/oauth/v2/token?grant_type=client_credentials' }
  let(:http)        { double(Net::HTTP) }
  let(:response)    { double(Net::HTTPResponse) }

  before do
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
      'Accept' => 'application/json',
      'Authorization' => "Basic #{SECRETS.adp_creds}"
    ).and_return(response)
    expect(response).to receive(:body).and_return('{"access_token": "a-token-value"}')
  end

  describe '.call' do
    let!(:business_unit) do
      FactoryGirl.create(:business_unit,
        code: 'OTUS',
        name: 'OpenTable Inc.',
        active: true)
    end

    let!(:old_business_unit) do
      FactoryGirl.create(:business_unit,
        code: 'OLD',
        name: 'Old Business Name',
        active: true)
    end

    before do
      allow(URI).to receive(:parse)
        .with('https://api.adp.com/codelists/hr/v3/worker-management/business-units/WFN/1')
        .and_return(uri)
      allow(http).to receive(:get)
        .with(request_uri, 'Accept' => 'application/json', 'Authorization' => 'Bearer a-token-value')
        .and_return(response)
      allow(response).to receive(:code)
      allow(response).to receive(:message)
      allow(response).to receive(:body)
        .and_return('{"codeLists": [{"codeListTitle": "business-units","listItems": [{"valueDescription": "OTAUS - Analytical Systems Pty Ltd.","codeValue": "OTAUS","longName": "Analytical Systems Pty Ltd."},{"valueDescription": "OTUS - OpenTable Inc.","codeValue": "OTUS","shortName": "OpenTable Inc."}]}]}')

      AdpService::CodeLists::SyncBusinessUnits.call
    end

    it 'creates a new record for new business units' do
      expect(BusinessUnit.last.code).to eq('OTAUS')
    end

    it 'marks active business units as active' do
      expect(business_unit.reload.active).to eq(true)
    end

    it 'marks inactive business as not active' do
      expect(old_business_unit.reload.active).to eq(false)
    end
  end
end
