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

  describe "populate_workers" do
    let!(:employee) { FactoryGirl.create(:employee, employee_id: "101455")}
    let(:json) { JSON.parse(File.read(Rails.root.to_s+"/spec/fixtures/adp_workers.json")) }
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
      expect(adp).to receive(:sort_workers).and_return(sorted)

      adp.populate_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      expect(employee.reload.first_name).to eq("Sally Jesse")
    end
  end

  describe "sort_workers" do
    let(:json) { JSON.parse(File.read(Rails.root.to_s+"/spec/fixtures/adp_workers.json")) }

    it "should call gen_worker_hash if not terminated status" do
      # There are 3 workers indicated in the json file, one is terminated

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(adp).to receive(:gen_worker_hash).exactly(2).times
      adp.sort_workers(json)
    end

    it "should return worker array" do
      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(adp).to receive(:gen_worker_hash).twice.and_return({worker: "info"})
      expect(adp.sort_workers(json)).to eq([{worker: "info"}, {worker: "info"}])
    end
  end

  describe "gen_worker_hash" do
    let(:json) { JSON.parse(File.read(Rails.root.to_s+"/spec/fixtures/adp_workers.json")) }
    let!(:worker_type) { FactoryGirl.create(:worker_type, name: "Regular Full-Time", code: "FTR") }
    let!(:worker_type_2) { FactoryGirl.create(:worker_type, name: "Voluntary", code: "TVOL") }
    let!(:department) { FactoryGirl.create(:department, name: "People & Culture-HR & Total Rewards", code: "111000") }
    let!(:department_2) { FactoryGirl.create(:department, name: "Sales - General - Germany", code: "120710") }
    let!(:department_3) { FactoryGirl.create(:department, name: "Inside Sales", code: "125000") }
    let!(:location) { FactoryGirl.create(:location, name: "Las Vegas", code: "LAS") }
    let!(:location_2) { FactoryGirl.create(:location, name: "Germany", code: "GERMA", kind: "Remote Location") }
    let!(:job_title) { FactoryGirl.create(:job_title, name: "Sr. People Business Partner", code: "SRBP") }
    let!(:job_title_2) { FactoryGirl.create(:job_title, name: "Sales Representative, OTC", code: "SROTC") }
    let!(:job_title_3) { FactoryGirl.create(:job_title, name: "Sales Associate", code: "SADEN") }

    it "should create the hash from json" do
      w_json = json["workers"][2]

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(adp.gen_worker_hash(w_json)).to eq({
        status: "Active",
        adp_assoc_oid: "G32B8JAXA1W398Z8",
        first_name: "Shirley",
        last_name: "Allansberg",
        employee_id: "101455",
        hire_date: "2013-08-05",
        contract_end_date: nil,
        termination_date: nil,
        company: "OpenTable Inc.",
        job_title_id: job_title.id,
        worker_type_id: worker_type.id,
        manager_id: "101734",
        department_id: department.id,
        location_id: location.id,
        office_phone: "(212) 555-4411",
        personal_mobile_phone: "(212) 555-4411"
      })
    end

    it "should pick nickname if exists" do
      w_json = json["workers"][0]

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(adp.gen_worker_hash(w_json)).to include({
        first_name: "Sally Jesse",
      })
    end

    it "should pick preferred last_name if exists" do
      w_json = json["workers"][0]

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(adp.gen_worker_hash(w_json)).to include({
        last_name: "Smith",
      })
    end

    it "should find worker end date if exists" do
      w_json = json["workers"][1]

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(adp.gen_worker_hash(w_json)).to include({
        contract_end_date: "2017-01-20"
      })
    end

    it "should pull address info if the worker is Remote" do
      w_json = json["workers"][0]

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(adp.gen_worker_hash(w_json)).to include({
        home_address_1: "Zeukerstrasse 123",
        home_address_2: nil,
        home_city: "Frankfurt",
        home_state: "Hessen",
        home_zip: "5384980"
      })
    end

    it "should not pull address info if the worker is Remote" do
      w_json = json["workers"][1]

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(adp.gen_worker_hash(w_json)).to_not include({
        home_address_1: "2890 Beach Blvd",
        home_address_2: "Apt 222",
        home_city: "Denver",
        home_state: "CO",
        home_zip: "63748"
      })
    end
  end
end
