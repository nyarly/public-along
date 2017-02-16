require 'rails_helper'

describe AdpService::Workers, type: :service do
  let(:url)         { "https://accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:uri)         { double(URI) }
  let(:host)        { "accounts.adp.com" }
  let(:port)        { 443 }
  let(:request_uri) { "/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:http)        { double(Net::HTTP) }
  let(:response)    { double(Net::HTTPResponse) }

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
    expect(response).to receive(:body).and_return('{"access_token": "7890f85c-43ef-4ebc-acb7-f98f2c0581d0"}')
  end

  it "should get a bearer token from ADP" do
    expect(AdpService::Workers.new.token).to eq("7890f85c-43ef-4ebc-acb7-f98f2c0581d0")
  end

  describe "worker_count" do
    before :each do
      expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers?$select=workers/workerStatus&$top=1&count=true").and_return(uri)
      expect(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should find a worker count" do
      expect(response).to receive(:body).and_return('{"meta":{"totalNumber": 1800}}')

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(adp.worker_count).to eq(1800)
    end
  end

  describe "create_worker_urls" do
    it "should create URL pages to call based on count" do

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(adp).to receive(:worker_count).and_return(375)

      expect(adp.create_worker_urls).to eq([
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=0",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=25",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=50",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=75",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=100",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=125",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=150",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=175",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=200",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=225",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=250",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=275",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=300",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=325",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=350",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=375"
      ])
    end
  end

  describe "create_sidekiq_workers" do
    it "should call sidekiq workers" do
      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(adp).to receive(:worker_count).and_return(175)

      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=0")
      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=50")
      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=75")
      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=100")
      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=125")
      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=150")
      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=175")

      adp.create_sidekiq_workers
    end
  end

  describe "sync_workers" do
    let!(:employee) { FactoryGirl.create(:employee, employee_id: "101455")}
    let(:json) { JSON.parse(File.read(Rails.root.to_s+"/spec/fixtures/adp_workers.json")) }
    let(:parser) { double(AdpService::WorkerJsonParser) }
    let(:sorted) {
      [{
        status: "Active",
        adp_assoc_oid: "G32B8JAXA1W398Z8",
        first_name: "Sally Jesse",
        last_name: "Allansberg",
        employee_id: "101455",
        hire_date: "2013-08-05",
        contract_end_date: nil,
        termination_date: nil,
        company: "OpenTable Inc.",
        job_title_id: 1,
        worker_type_id: 2,
        manager_id: "101734",
        department_id: 3,
        location_id: 4,
        office_phone: "(212) 555-4411",
        personal_mobile_phone: "(212) 555-4411"
      }]
    }
    let(:ads) { double(ActiveDirectoryService) }

    before :each do
      expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=25").and_return(uri)
      expect(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should call parse json response, call #sort_workers and update employees" do
      expect(response).to receive(:body).and_return(json)

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(JSON).to receive(:parse).with(json)
      expect(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
      expect(parser).to receive(:sort_workers).and_return(sorted)
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:update).with([employee])

      adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      expect(employee.reload.first_name).to eq("Sally Jesse")
    end
  end
end
