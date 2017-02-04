require 'rails_helper'

describe AdpService, type: :service do
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

    expect(URI).to receive(:parse).with(url).and_return(uri)
    expect(Net::HTTP).to receive(:new).with(host, port).and_return(http).at_least(:once)
    expect(http).to receive(:read_timeout=).with(200).at_least(:once)
    expect(http).to receive(:use_ssl=).with(true).at_least(:once)
    expect(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER).at_least(:once)
    expect(http).to receive(:post).with(
      request_uri,
      '',
      { "Accept"=>"application/json",
        "Authorization"=>"Basic #{SECRETS.adp_creds}",
      }).and_return(response)
    expect(response).to receive(:body).and_return('{"access_token": "7890f85c-43ef-4ebc-acb7-f98f2c0581d0"}')
  end

  describe "get_bearer_token" do
    it "should get a bearer token from ADP" do
      expect(AdpService.new("prod").token).to eq("7890f85c-43ef-4ebc-acb7-f98f2c0581d0")
    end
  end

  describe "populate job titles table" do
    let!(:existing) { FactoryGirl.create(:job_title, code: "ACCNASST", name: "Accounting Assistant", status: "Active")}

    before :each do
      expect(URI).to receive(:parse).with("https://api.adp.com/codelists/hr/v3/worker-management/job-titles/WFN/1").and_return(uri)
      expect(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should find or create job titles" do
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"job-titles","listItems":[{"valueDescription":"AASFE - Administrative Assistant","codeValue":"AASFE","longName":"Administrative Assistant"},{"valueDescription":"ACCNASST - Accounting Assistant","codeValue":"ACCNASST","shortName":"Accounting Assistant"},{"valueDescription":"ACCPAYSU - Accounts Payable Supervisor","codeValue":"ACCPAYSU","longName":"Accounts Payable Supervisor"}]}]}')

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect{
        adp.populate_job_titles
      }.to change{JobTitle.count}.from(1).to(3)
    end

    it "should update changes in existing job titles" do
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"job-titles","listItems":[{"valueDescription":"AASFE - Administrative Assistant","codeValue":"AASFE","longName":"Administrative Assistant"},{"valueDescription":"ACCNASST - Accounting Assistant","codeValue":"ACCNASST","shortName":"New Accounting Assistant"},{"valueDescription":"ACCPAYSU - Accounts Payable Supervisor","codeValue":"ACCPAYSU","longName":"Accounts Payable Supervisor"}]}]}')

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect{
        adp.populate_job_titles
      }.to change{JobTitle.find_by(code: "ACCNASST").name}.from("Accounting Assistant").to("New Accounting Assistant")
    end

    it "should assign status dependent on presence in response body" do
      inactive = FactoryGirl.create(:job_title, code: "ACCPAYSU", name: "Accounts Payable Supervisor", status: "Active")

      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"job-titles","listItems":[{"valueDescription":"AASFE - Administrative Assistant","codeValue":"AASFE","longName":"Administrative Assistant"},{"valueDescription":"ACCNASST - Accounting Assistant","codeValue":"ACCNASST","shortName":"New Accounting Assistant"}]}]}')

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect{
        adp.populate_job_titles
      }.to change{JobTitle.find_by(code: "ACCPAYSU").status}.from("Active").to("Inactive")
      expect(JobTitle.find_by(code: "AASFE").status).to eq("Active")
      expect(JobTitle.find_by(code: "ACCNASST").status).to eq("Active")
    end
  end

  describe "populate locations table" do

    before :each do
      Location.destroy_all
      expect(URI).to receive(:parse).with("https://api.adp.com/codelists/hr/v3/worker-management/locations/WFN/1").and_return(uri)
      expect(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should find or create locations" do
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"locations","listItems":[{"valueDescription":"AB - Alberta", "codeValue":"AB", "shortName":"Alberta"}, {"valueDescription":"AZ - Arizona", "codeValue":"AZ", "shortName":"Arizona"}, {"valueDescription":"BC - British Columbia", "codeValue":"BC", "shortName":"British Columbia"}, {"valueDescription":"BER - Berlin", "codeValue":"BER", "shortName":"Berlin"}, {"valueDescription":"BM - Birmingham", "codeValue":"BM", "shortName":"Birmingham"}]}]}')

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect{
        adp.populate_locations
      }.to change{Location.count}.from(0).to(5)
    end

    it "should update changes in existing locations" do
      existing = FactoryGirl.create(:location, code: "AB", name: "Alberta", status: "Active", country: "CA", kind: "Remote Location", timezone: "(GMT-07:00) Mountain Time (US & Canada)")
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"locations","listItems":[{"valueDescription":"AB - Alberta", "codeValue":"AB", "shortName":"New Alberta"}, {"valueDescription":"AZ - Arizona", "codeValue":"AZ", "shortName":"Arizona"}, {"valueDescription":"BC - British Columbia", "codeValue":"BC", "shortName":"British Columbia"}, {"valueDescription":"BER - Berlin", "codeValue":"BER", "shortName":"Berlin"}, {"valueDescription":"BM - Birmingham", "codeValue":"BM", "shortName":"Birmingham"}]}]}')

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect{
        adp.populate_locations
      }.to change{Location.find_by(code: "AB").name}.from("Alberta").to("New Alberta")
      expect(Location.find_by(code: "AB").country).to eq("CA")
      expect(Location.find_by(code: "AB").kind).to eq("Remote Location")
      expect(Location.find_by(code: "AB").timezone).to eq("(GMT-07:00) Mountain Time (US & Canada)")
      expect(Location.find_by(code: "AZ").country).to eq("Pending Assignment")
      expect(Location.find_by(code: "AZ").kind).to eq("Pending Assignment")
      expect(Location.find_by(code: "AZ").timezone).to eq("Pending Assignment")
    end

    it "should assign status dependent on presence in response body" do
      inactive = FactoryGirl.create(:location, code: "CHA", name: "Chattanooga", status: "Active")

      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"locations","listItems":[{"valueDescription":"AB - Alberta", "codeValue":"AB", "shortName":"New Alberta"}, {"valueDescription":"AZ - Arizona", "codeValue":"AZ", "shortName":"Arizona"}, {"valueDescription":"BC - British Columbia", "codeValue":"BC", "shortName":"British Columbia"}, {"valueDescription":"BER - Berlin", "codeValue":"BER", "shortName":"Berlin"}, {"valueDescription":"BM - Birmingham", "codeValue":"BM", "shortName":"Birmingham"}]}]}')

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect{
        adp.populate_locations
      }.to change{Location.find_by(code: "CHA").status}.from("Active").to("Inactive")
      expect(Location.find_by(code: "AB").status).to eq("Active")
      expect(Location.find_by(code: "AZ").status).to eq("Active")
    end
  end

  describe "populate departments table" do

    before :each do
      Department.destroy_all
      expect(URI).to receive(:parse).with("https://api.adp.com/codelists/hr/v3/worker-management/departments/WFN/1").and_return(uri)
      expect(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should find or create departments" do
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"departments","listItems":[{"valueDescription":"010000 - Facilities", "foreignKey":"WP8", "codeValue":"010000", "shortName":"Facilities"},{"valueDescription":"011000 - People & Culture-HR & Total Rewards", "foreignKey":"WP8", "codeValue":"011000", "longName":"People & Culture-HR & Total Rewards"},{"valueDescription":"012000 - Legal", "foreignKey":"WP8", "codeValue":"012000", "shortName":"Legal"},{"valueDescription":"013000 - Finance", "foreignKey":"WP8", "codeValue":"013000", "shortName":"Finance"},{"valueDescription":"014000 - Risk Management", "foreignKey":"WP8", "codeValue":"014000", "shortName":"Risk Management"}]}]}')

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect{
        adp.populate_departments
      }.to change{Department.count}.from(0).to(5)
    end

    it "should update changes in existing departments" do
      existing = FactoryGirl.create(:department, code: "010000", name: "Facilities")
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"departments","listItems":[{"valueDescription":"010000 - Facilities", "foreignKey":"WP8", "codeValue":"010000", "shortName":"New Facilities"},{"valueDescription":"011000 - People & Culture-HR & Total Rewards", "foreignKey":"WP8", "codeValue":"011000", "longName":"People & Culture-HR & Total Rewards"},{"valueDescription":"012000 - Legal", "foreignKey":"WP8", "codeValue":"012000", "shortName":"Legal"},{"valueDescription":"013000 - Finance", "foreignKey":"WP8", "codeValue":"013000", "shortName":"Finance"},{"valueDescription":"014000 - Risk Management", "foreignKey":"WP8", "codeValue":"014000", "shortName":"Risk Management"}]}]}')

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect{
        adp.populate_departments
      }.to change{Department.find_by(code: "010000").name}.from("Facilities").to("New Facilities")
    end

    it "should assign status dependent on presence in response body" do
      inactive = FactoryGirl.create(:department, code:"014000", name:"Risk Management", status: "Active")

      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"departments","listItems":[{"valueDescription":"010000 - Facilities", "foreignKey":"WP8", "codeValue":"010000", "shortName":"New Facilities"},{"valueDescription":"011000 - People & Culture-HR & Total Rewards", "foreignKey":"WP8", "codeValue":"011000", "longName":"People & Culture-HR & Total Rewards"},{"valueDescription":"012000 - Legal", "foreignKey":"WP8", "codeValue":"012000", "shortName":"Legal"},{"valueDescription":"013000 - Finance", "foreignKey":"WP8", "codeValue":"013000", "shortName":"Finance"}]}]}')

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect{
        adp.populate_departments
      }.to change{Department.find_by(code: "014000").status}.from("Active").to("Inactive")
      expect(Department.find_by(code: "010000").status).to eq("Active")
      expect(Department.find_by(code: "011000").status).to eq("Active")
    end
  end

  describe "populate worker types table" do

    before :each do
      WorkerType.destroy_all
      expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/meta").and_return(uri)
      expect(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should find or create worker types" do
      expect(response).to receive(:body).and_return('{"meta":{"/workers/workAssignments/workerTypeCode":{"codeList":{"listItems":[{"codeValue":"", "shortName":""}, {"codeValue":"ACW", "shortName":"Agency Worker"}, {"codeValue":"CONT", "shortName":"Contractor"}, {"codeValue":"CT3P", "longName":"Contractor - 3rd Party"}, {"codeValue":"F", "shortName":"Full Time"}, {"codeValue":"FTC", "shortName":"Contractor Full-Time"}, {"codeValue":"FTF", "shortName":"Fixed Term Full Time"}, {"codeValue":"FTR", "shortName":"Regular Full-Time"}, {"codeValue":"FTT", "shortName":"Temporary Full-Time"}, {"codeValue":"OLFR", "shortName":"Regular Full-Time"}]}, "readOnly":true, "optional":true, "hidden":false, "shortLabelName":"Worker Category"}}}')

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect{
        adp.populate_worker_types
      }.to change{WorkerType.count}.from(0).to(9)
    end

    it "should update changes in existing worker types" do
      existing = FactoryGirl.create(:worker_type, code: "ACW", name: "Agency Worker")
      expect(response).to receive(:body).and_return('{"meta":{"/workers/workAssignments/workerTypeCode":{"codeList":{"listItems":[{"codeValue":"", "shortName":""}, {"codeValue":"ACW", "shortName":"New Agency Worker"}, {"codeValue":"CONT", "shortName":"Contractor"}, {"codeValue":"CT3P", "longName":"Contractor - 3rd Party"}, {"codeValue":"F", "shortName":"Full Time"}, {"codeValue":"FTC", "shortName":"Contractor Full-Time"}, {"codeValue":"FTF", "shortName":"Fixed Term Full Time"}, {"codeValue":"FTR", "shortName":"Regular Full-Time"}, {"codeValue":"FTT", "shortName":"Temporary Full-Time"}, {"codeValue":"OLFR", "shortName":"Regular Full-Time"}]}, "readOnly":true, "optional":true, "hidden":false, "shortLabelName":"Worker Category"}}}')

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect{
        adp.populate_worker_types
      }.to change{WorkerType.find_by(code: "ACW").name}.from("Agency Worker").to("New Agency Worker")
    end

    it "should assign status dependent on presence in response body" do
      inactive = FactoryGirl.create(:worker_type, code: "SRP", name: "SRP Worker", status: "Active")

      expect(response).to receive(:body).and_return('{"meta":{"/workers/workAssignments/workerTypeCode":{"codeList":{"listItems":[{"codeValue":"", "shortName":""}, {"codeValue":"ACW", "shortName":"Agency Worker"}, {"codeValue":"CONT", "shortName":"Contractor"}, {"codeValue":"CT3P", "longName":"Contractor - 3rd Party"}, {"codeValue":"F", "shortName":"Full Time"}, {"codeValue":"FTC", "shortName":"Contractor Full-Time"}, {"codeValue":"FTF", "shortName":"Fixed Term Full Time"}, {"codeValue":"FTR", "shortName":"Regular Full-Time"}, {"codeValue":"FTT", "shortName":"Temporary Full-Time"}, {"codeValue":"OLFR", "shortName":"Regular Full-Time"}]}, "readOnly":true, "optional":true, "hidden":false, "shortLabelName":"Worker Category"}}}')

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect{
        adp.populate_worker_types
      }.to change{WorkerType.find_by(code: "SRP").status}.from("Active").to("Inactive")
      expect(WorkerType.find_by(code: "CONT").status).to eq("Active")
      expect(WorkerType.find_by(code: "F").status).to eq("Active")
    end
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

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect(adp.worker_count).to eq(1800)
    end
  end

  describe "create_worker_urls" do
    it "should create URL pages to call based on count" do

      adp = AdpService.new("prod")
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
      adp = AdpService.new("prod")
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
    before :each do
      expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=25").and_return(uri)
      expect(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should call parse json response and call #sort_workers" do
      expect(response).to receive(:body).and_return('{"some":{"json": "values"}}')

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect(JSON).to receive(:parse).with('{"some":{"json": "values"}}').and_return("json parsed values")
      expect(adp).to receive(:sort_workers).with("json parsed values")

      adp.populate_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
    end
  end

  describe "sort_workers" do
    let(:json) { JSON.parse(File.read(Rails.root.to_s+"/spec/fixtures/adp_workers.json")) }

    it "should call gen_worker_hash if not terminated status" do
      # There are 3 workers indicated in the json file, one is terminated

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect(adp).to receive(:gen_worker_hash).exactly(2).times
      adp.sort_workers(json)
    end

    it "should return worker array" do
      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect(adp).to receive(:gen_worker_hash).twice.and_return({worker: "info"})
      expect(adp.sort_workers(json)).to eq([{worker: "info"}, {worker: "info"}])
    end
  end

  describe "gen_worker_hash" do
    let(:json) { JSON.parse(File.read(Rails.root.to_s+"/spec/fixtures/adp_workers.json")) }
    let!(:worker_type) { FactoryGirl.create(:worker_type, name: "Regular Full-Time", code: "FTR") }
    let!(:worker_type_2) { FactoryGirl.create(:worker_type, name: "Voluntary", code: "TVOL") }
    let!(:department) { FactoryGirl.create(:department, name: "People & Culture-HR & Total Rewards", code: "011000") }
    let!(:department_2) { FactoryGirl.create(:department, name: "Sales - General - Germany", code: "020710") }
    let!(:department_3) { FactoryGirl.create(:department, name: "Inside Sales", code: "025000") }
    let!(:location) { FactoryGirl.create(:location, name: "Las Vegas", code: "LAS") }
    let!(:location_2) { FactoryGirl.create(:location, name: "Germany", code: "GERMA", kind: "Remote Location") }
    let!(:job_title) { FactoryGirl.create(:job_title, name: "Sr. People Business Partner", code: "SRBP") }
    let!(:job_title_2) { FactoryGirl.create(:job_title, name: "Sales Representative, OTC", code: "SROTC") }
    let!(:job_title_3) { FactoryGirl.create(:job_title, name: "Sales Associate", code: "SADEN") }

    it "should create the hash from json" do
      w_json = json["workers"][2]

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect(adp.gen_worker_hash(w_json)).to eq({
        status: "Active",
        adp_assoc_oid: "G32B8JAXA1W398Z8",
        first_name: "Sally",
        last_name: "Allansberg",
        employee_id: "101455",
        hire_date: "2013-08-05",
        contract_end_date: nil,
        termination_date: nil,
        company: "OTUS",
        job_title_id: job_title.id,
        worker_type_id: worker_type.id,
        manager_id: "101734",
        department_id: department.id,
        location_id: location.id,
        office_phone: "(212) 555-4411",
        personal_mobile_phone: "(212) 555-4411"
      })
    end

    it "should pick the first name in nickname if exists" do
      w_json = json["workers"][0]

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect(adp.gen_worker_hash(w_json)).to include({
        first_name: "Sally",
      })
    end

    it "should find worker end date if exists" do
      w_json = json["workers"][1]

      adp = AdpService.new("prod")
      adp.token = "a-token-value"

      expect(adp.gen_worker_hash(w_json)).to include({
        contract_end_date: "2017-01-20"
      })
    end

    it "should pull address info if the worker is Remote" do
      w_json = json["workers"][0]

      adp = AdpService.new("prod")
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

      adp = AdpService.new("prod")
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
