require 'rails_helper'

describe AdpService::CodeLists::SyncLocations, type: :service do
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
      { "Accept"=>"application/json",
        "Authorization"=>"Basic #{SECRETS.adp_creds}",
      }).and_return(response)
    expect(response).to receive(:body).and_return('{"access_token": "a-token-value"}')
  end

  describe '.call' do
    let(:mailer) { double(PeopleAndCultureMailer) }
    let!(:location) do
      FactoryGirl.create(:location,
        code: 'LOC',
        status: 'Active')
    end

    let!(:old_location) do
      FactoryGirl.create(:location,
        code: 'OLDLOC',
        status: 'Active')
    end

    before do
      allow(PeopleAndCultureMailer).to receive(:code_list_alert).and_return(mailer)
      allow(mailer).to receive(:deliver_now)
      allow(URI).to receive(:parse)
        .with('https://api.adp.com/codelists/hr/v3/worker-management/locations/WFN/1')
        .and_return(uri)
      allow(http).to receive(:get)
        .with(request_uri, { "Accept" => "application/json", "Authorization" => "Bearer a-token-value" })
        .and_return(response)
      allow(response).to receive(:code)
      allow(response).to receive(:message)
      allow(response).to receive(:body)
        .and_return('{"codeLists":[{"codeListTitle":"locations","listItems":[{"valueDescription":"NEWLOC - New Location", "codeValue":"NEWLOC", "shortName":"New Location"}, {"valueDescription":"LOC - The location", "codeValue":"LOC", "shortName":"The location"}]}]}')

      AdpService::CodeLists::SyncLocations.call
    end

    it 'creates a new record for new locations' do
      expect(Location.find_by(code: 'NEWLOC').status).to eq('Active')
    end

    it 'sends P&C an email to update new items' do
      expect(PeopleAndCultureMailer).to have_received(:code_list_alert)
      expect(mailer).to have_received(:deliver_now)
    end

    it 'active location has status of Active' do
      expect(location.status).to eq('Active')
    end

    it 'inactive location has status of Inactive' do
      expect(old_location.reload.status).to eq('Inactive')
    end
  end
end
