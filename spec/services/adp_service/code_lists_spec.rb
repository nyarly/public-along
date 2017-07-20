require 'rails_helper'

describe AdpService::CodeLists, type: :service do
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
    expect(AdpService::CodeLists.new.token).to eq("7890f85c-43ef-4ebc-acb7-f98f2c0581d0")
  end

  describe "sync job titles table" do
    let!(:existing) { FactoryGirl.create(:job_title, code: "ACCNASST", name: "Accounting Assistant", status: "Active")}

    before :each do
      allow(URI).to receive(:parse).with("https://api.adp.com/codelists/hr/v3/worker-management/job-titles/WFN/1").and_return(uri)
      allow(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should find or create job titles" do
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"job-titles","listItems":[{"valueDescription":"AASFE - Administrative Assistant","codeValue":"AASFE","longName":"Administrative Assistant"},{"valueDescription":"ACCNASST - Accounting Assistant","codeValue":"ACCNASST","shortName":"Accounting Assistant"},{"valueDescription":"ACCPAYSU - Accounts Payable Supervisor","codeValue":"ACCPAYSU","longName":"Accounts Payable Supervisor"}]}]}')

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect{
        adp.sync_job_titles
      }.to change{JobTitle.count}.from(1).to(3)
    end

    it "should update changes in existing job titles" do
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"job-titles","listItems":[{"valueDescription":"AASFE - Administrative Assistant","codeValue":"AASFE","longName":"Administrative Assistant"},{"valueDescription":"ACCNASST - Accounting Assistant","codeValue":"ACCNASST","shortName":"New Accounting Assistant"},{"valueDescription":"ACCPAYSU - Accounts Payable Supervisor","codeValue":"ACCPAYSU","longName":"Accounts Payable Supervisor"}]}]}')

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect{
        adp.sync_job_titles
      }.to change{JobTitle.find_by(code: "ACCNASST").name}.from("Accounting Assistant").to("New Accounting Assistant")
    end

    it "should assign status dependent on presence in response body" do
      inactive = FactoryGirl.create(:job_title, code: "ACCPAYSU", name: "Accounts Payable Supervisor", status: "Active")

      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"job-titles","listItems":[{"valueDescription":"AASFE - Administrative Assistant","codeValue":"AASFE","longName":"Administrative Assistant"},{"valueDescription":"ACCNASST - Accounting Assistant","codeValue":"ACCNASST","shortName":"New Accounting Assistant"}]}]}')

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect{
        adp.sync_job_titles
      }.to change{JobTitle.find_by(code: "ACCPAYSU").status}.from("Active").to("Inactive")
      expect(JobTitle.find_by(code: "AASFE").status).to eq("Active")
      expect(JobTitle.find_by(code: "ACCNASST").status).to eq("Active")
    end
  end

  describe "sync locations table" do

    before :each do
      Location.destroy_all
      allow(URI).to receive(:parse).with("https://api.adp.com/codelists/hr/v3/worker-management/locations/WFN/1").and_return(uri)
      allow(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should find or create locations" do
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"locations","listItems":[{"valueDescription":"AB - Alberta", "codeValue":"AB", "shortName":"Alberta"}, {"valueDescription":"AZ - Arizona", "codeValue":"AZ", "shortName":"Arizona"}, {"valueDescription":"BC - British Columbia", "codeValue":"BC", "shortName":"British Columbia"}, {"valueDescription":"BER - Berlin", "codeValue":"BER", "shortName":"Berlin"}, {"valueDescription":"BM - Birmingham", "codeValue":"BM", "shortName":"Birmingham"}]}]}')

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect{
        adp.sync_locations
      }.to change{Location.count}.from(0).to(5)
    end

    it "should update changes in existing locations" do
      existing = FactoryGirl.create(:location, code: "AB", name: "Alberta", status: "Active", country: "CA", kind: "Remote Location", timezone: "(GMT-07:00) Mountain Time (US & Canada)")
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"locations","listItems":[{"valueDescription":"AB - Alberta", "codeValue":"AB", "shortName":"New Alberta"}, {"valueDescription":"AZ - Arizona", "codeValue":"AZ", "shortName":"Arizona"}, {"valueDescription":"BC - British Columbia", "codeValue":"BC", "shortName":"British Columbia"}, {"valueDescription":"BER - Berlin", "codeValue":"BER", "shortName":"Berlin"}, {"valueDescription":"BM - Birmingham", "codeValue":"BM", "shortName":"Birmingham"}]}]}')

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect{
        adp.sync_locations
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

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect{
        adp.sync_locations
      }.to change{Location.find_by(code: "CHA").status}.from("Active").to("Inactive")
      expect(Location.find_by(code: "AB").status).to eq("Active")
      expect(Location.find_by(code: "AZ").status).to eq("Active")
    end

    it "should send p&c an email to update new items" do
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"locations","listItems":[{"valueDescription":"AB - Alberta", "codeValue":"AB", "shortName":"Alberta"}]}]}')

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect(PeopleAndCultureMailer).to receive_message_chain(:code_list_alert, :deliver_now)
      adp.sync_locations
      expect(Location.find_by(code: "AB").kind).to eq("Pending Assignment")
    end
  end

  describe "sync departments table" do

    before :each do
      Department.destroy_all
      allow(URI).to receive(:parse).with("https://api.adp.com/codelists/hr/v3/worker-management/departments/WFN/1").and_return(uri)
      allow(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should find or create departments" do
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"departments","listItems":[{"valueDescription":"010000 - Facilities", "foreignKey":"WP8", "codeValue":"010000", "shortName":"Facilities"},{"valueDescription":"011000 - People & Culture-HR & Total Rewards", "foreignKey":"WP8", "codeValue":"011000", "longName":"People & Culture-HR & Total Rewards"},{"valueDescription":"012000 - Legal", "foreignKey":"WP8", "codeValue":"012000", "shortName":"Legal"},{"valueDescription":"013000 - Finance", "foreignKey":"WP8", "codeValue":"013000", "shortName":"Finance"},{"valueDescription":"014000 - Risk Management", "foreignKey":"WP8", "codeValue":"014000", "shortName":"Risk Management"}]}]}')

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect{
        adp.sync_departments
      }.to change{Department.count}.from(0).to(5)
    end

    it "should update changes in existing departments" do
      existing = FactoryGirl.create(:department, code: "010000", name: "Facilities")
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"departments","listItems":[{"valueDescription":"010000 - Facilities", "foreignKey":"WP8", "codeValue":"010000", "shortName":"New Facilities"},{"valueDescription":"011000 - People & Culture-HR & Total Rewards", "foreignKey":"WP8", "codeValue":"011000", "longName":"People & Culture-HR & Total Rewards"},{"valueDescription":"012000 - Legal", "foreignKey":"WP8", "codeValue":"012000", "shortName":"Legal"},{"valueDescription":"013000 - Finance", "foreignKey":"WP8", "codeValue":"013000", "shortName":"Finance"},{"valueDescription":"014000 - Risk Management", "foreignKey":"WP8", "codeValue":"014000", "shortName":"Risk Management"}]}]}')

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect{
        adp.sync_departments
      }.to change{Department.find_by(code: "010000").name}.from("Facilities").to("New Facilities")
    end

    it "should assign status dependent on presence in response body" do
      inactive = FactoryGirl.create(:department, code:"014000", name:"Risk Management", status: "Active")

      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"departments","listItems":[{"valueDescription":"010000 - Facilities", "foreignKey":"WP8", "codeValue":"010000", "shortName":"New Facilities"},{"valueDescription":"011000 - People & Culture-HR & Total Rewards", "foreignKey":"WP8", "codeValue":"011000", "longName":"People & Culture-HR & Total Rewards"},{"valueDescription":"012000 - Legal", "foreignKey":"WP8", "codeValue":"012000", "shortName":"Legal"},{"valueDescription":"013000 - Finance", "foreignKey":"WP8", "codeValue":"013000", "shortName":"Finance"}]}]}')

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect{
        adp.sync_departments
      }.to change{Department.find_by(code: "014000").status}.from("Active").to("Inactive")
      expect(Department.find_by(code: "010000").status).to eq("Active")
      expect(Department.find_by(code: "011000").status).to eq("Active")
    end

    it "should send p&c an email to update new items" do
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"departments","listItems":[{"valueDescription":"007 - Engineering", "foreignKey":"WP8", "codeValue":"007", "shortName":"Engineering"}]}]}')

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect(PeopleAndCultureMailer).to receive_message_chain(:code_list_alert, :deliver_now)
      adp.sync_departments
      expect(Department.find_by(code: "007").parent_org_id).to eq(nil)
    end
  end

  describe "sync worker types table" do

    before :each do
      WorkerType.destroy_all
      allow(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/meta").and_return(uri)
      allow(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should find or create worker types" do
      expect(response).to receive(:body).and_return('{"meta":{"/workers/workAssignments/workerTypeCode":{"codeList":{"listItems":[{"codeValue":"", "shortName":""}, {"codeValue":"ACW", "shortName":"Agency Worker"}, {"codeValue":"CONT", "shortName":"Contractor"}, {"codeValue":"CT3P", "longName":"Contractor - 3rd Party"}, {"codeValue":"F", "shortName":"Full Time"}, {"codeValue":"FTC", "shortName":"Contractor Full-Time"}, {"codeValue":"FTF", "shortName":"Fixed Term Full Time"}, {"codeValue":"FTR", "shortName":"Regular Full-Time"}, {"codeValue":"FTT", "shortName":"Temporary Full-Time"}, {"codeValue":"OLFR", "shortName":"Regular Full-Time"}]}, "readOnly":true, "optional":true, "hidden":false, "shortLabelName":"Worker Category"}}}')

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect{
        adp.sync_worker_types
      }.to change{WorkerType.count}.from(0).to(9)
    end

    it "should update changes in existing worker types" do
      existing = FactoryGirl.create(:worker_type, code: "ACW", name: "Agency Worker")
      expect(response).to receive(:body).and_return('{"meta":{"/workers/workAssignments/workerTypeCode":{"codeList":{"listItems":[{"codeValue":"", "shortName":""}, {"codeValue":"ACW", "shortName":"New Agency Worker"}, {"codeValue":"CONT", "shortName":"Contractor"}, {"codeValue":"CT3P", "longName":"Contractor - 3rd Party"}, {"codeValue":"F", "shortName":"Full Time"}, {"codeValue":"FTC", "shortName":"Contractor Full-Time"}, {"codeValue":"FTF", "shortName":"Fixed Term Full Time"}, {"codeValue":"FTR", "shortName":"Regular Full-Time"}, {"codeValue":"FTT", "shortName":"Temporary Full-Time"}, {"codeValue":"OLFR", "shortName":"Regular Full-Time"}]}, "readOnly":true, "optional":true, "hidden":false, "shortLabelName":"Worker Category"}}}')

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect{
        adp.sync_worker_types
      }.to change{WorkerType.find_by(code: "ACW").name}.from("Agency Worker").to("New Agency Worker")
    end

    it "should assign status dependent on presence in response body" do
      inactive = FactoryGirl.create(:worker_type, code: "SRP", name: "SRP Worker", status: "Active")

      expect(response).to receive(:body).and_return('{"meta":{"/workers/workAssignments/workerTypeCode":{"codeList":{"listItems":[{"codeValue":"", "shortName":""}, {"codeValue":"ACW", "shortName":"Agency Worker"}, {"codeValue":"CONT", "shortName":"Contractor"}, {"codeValue":"CT3P", "longName":"Contractor - 3rd Party"}, {"codeValue":"F", "shortName":"Full Time"}, {"codeValue":"FTC", "shortName":"Contractor Full-Time"}, {"codeValue":"FTF", "shortName":"Fixed Term Full Time"}, {"codeValue":"FTR", "shortName":"Regular Full-Time"}, {"codeValue":"FTT", "shortName":"Temporary Full-Time"}, {"codeValue":"OLFR", "shortName":"Regular Full-Time"}]}, "readOnly":true, "optional":true, "hidden":false, "shortLabelName":"Worker Category"}}}')

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect{
        adp.sync_worker_types
      }.to change{WorkerType.find_by(code: "SRP").status}.from("Active").to("Inactive")
      expect(WorkerType.find_by(code: "CONT").status).to eq("Active")
      expect(WorkerType.find_by(code: "F").status).to eq("Active")
    end

    it "should send p&c an email to update new items" do
      expect(response).to receive(:body).and_return('{"meta":{"/workers/workAssignments/workerTypeCode":{"codeList":{"listItems":[{"codeValue":"", "shortName":""}, {"codeValue":"ACW", "shortName":"Agency Worker"}, {"codeValue":"CONT", "shortName":"Contractor"}, {"codeValue":"CT3P", "longName":"Contractor - 3rd Party"}, {"codeValue":"F", "shortName":"Full Time"}, {"codeValue":"FTC", "shortName":"Contractor Full-Time"}, {"codeValue":"FTF", "shortName":"Fixed Term Full Time"}, {"codeValue":"FTR", "shortName":"Regular Full-Time"}, {"codeValue":"FTT", "shortName":"Temporary Full-Time"}, {"codeValue":"OLFR", "shortName":"Regular Full-Time"}]}, "readOnly":true, "optional":true, "hidden":false, "shortLabelName":"Worker Category"}}}')

      adp = AdpService::CodeLists.new
      adp.token = "a-token-value"

      expect(PeopleAndCultureMailer).to receive_message_chain(:code_list_alert, :deliver_now)
      adp.sync_worker_types
      expect(WorkerType.find_by(code: "ACW").kind).to eq("Pending Assignment")
    end
  end
end
