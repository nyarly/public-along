require 'rails_helper'

describe AdpService::CodeLists::SyncJobTitles, type: :service do
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
    let!(:job_title) do
      FactoryGirl.create(:job_title,
        code: 'JOB',
        status: 'Active')
    end

    let!(:old_job_title) do
      FactoryGirl.create(:job_title,
        code: 'OLDJOB',
        status: 'Active')
    end

    before do
      allow(URI).to receive(:parse)
        .with('https://api.adp.com/codelists/hr/v3/worker-management/job-titles/WFN/1')
        .and_return(uri)
      allow(http).to receive(:get)
        .with(request_uri, { "Accept" => "application/json", "Authorization" => "Bearer a-token-value" })
        .and_return(response)
      allow(response).to receive(:code)
      allow(response).to receive(:message)
      allow(response).to receive(:body)
        .and_return('{"codeLists":[{"codeListTitle":"job-titles","listItems":[{"valueDescription":"JOB - the job title","codeValue":"JOB","longName":"the job title"},{"valueDescription":"NEWJOB - the new job title","codeValue":"NEWJOB","shortName":"the new job title"}]}]}')

      AdpService::CodeLists::SyncJobTitles.call
    end

    it 'creates a new record for new job titles' do
      expect(JobTitle.find_by(code: 'NEWJOB').status).to eq('Active')
    end

    it 'active job title has status of Active' do
      expect(job_title.status).to eq('Active')
    end

    it 'inactive job title has status of Inactive' do
      expect(old_job_title.reload.status).to eq('Inactive')
    end
  end
end
