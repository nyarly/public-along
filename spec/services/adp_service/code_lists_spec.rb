require 'rails_helper'

describe AdpService::CodeLists, type: :service do
  let(:url)         { "https://accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:uri)         { double(URI) }
  let(:host)        { "accounts.adp.com" }
  let(:port)        { 443 }
  let(:request_uri) { "/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:http)        { double(Net::HTTP) }
  let(:response)    { double(Net::HTTPResponse) }
  let(:service) { double(ActiveDirectory::GlobalGroups::Generator) }

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
    allow(ActiveDirectory::GlobalGroups::Generator).to receive(:new).and_return(service)
    allow(service).to receive(:new_group)
  end

  it "should get a bearer token from ADP" do
    expect(AdpService::CodeLists.new.token).to eq("7890f85c-43ef-4ebc-acb7-f98f2c0581d0")
  end

  describe '#sync_job_titles' do
    let!(:existing) { FactoryGirl.create(:job_title, code: "ACCNASST", name: "Accounting Assistant", status: "Active")}

    before :each do
      allow(URI).to receive(:parse).with("https://api.adp.com/codelists/hr/v3/worker-management/job-titles/WFN/1").and_return(uri)
      allow(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
      expect(response).to receive(:code)
      expect(response).to receive(:message)
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

  describe '#sync_locations' do
    before do
      Location.destroy_all
      allow(URI).to receive(:parse)
        .with('https://api.adp.com/codelists/hr/v3/worker-management/locations/WFN/1')
        .and_return(uri)
      allow(http).to receive(:get)
        .with(request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
      allow(response).to receive(:code)
      allow(response).to receive(:message)
    end

    context 'with new locations' do
      let(:adp) { AdpService::CodeLists.new }

      before do
        adp.token = "a-token-value"
        allow(PeopleAndCultureMailer).to receive_message_chain(:code_list_alert, :deliver_now)
        allow(response).to receive(:body)
          .and_return('{"codeLists":[{"codeListTitle":"locations","listItems":[{"valueDescription":"AB - Alberta", "codeValue":"AB", "shortName":"Alberta"}, {"valueDescription":"AZ - Arizona", "codeValue":"AZ", "shortName":"Arizona"}, {"valueDescription":"BC - British Columbia", "codeValue":"BC", "shortName":"British Columbia"}, {"valueDescription":"BER - Berlin", "codeValue":"BER", "shortName":"Berlin"}, {"valueDescription":"BM - Birmingham", "codeValue":"BM", "shortName":"Birmingham"}]}]}')
      end

      it 'creates new location records' do
        expect{
          adp.sync_locations
        }.to change{ Location.count }.from(0).to(5)
      end

      it 'assigns pending assignment for country' do
        adp.sync_locations
        expect(Location.find_by(code: 'AB').country).to eq('Pending Assignment')
      end

      it 'assigns pending assignment for kind' do
        adp.sync_locations
        expect(Location.find_by(code: 'AB').kind).to eq('Pending Assignment')
      end

      it 'assigns pending assignment for timezone' do
        adp.sync_locations
        expect(Location.find_by(code: 'AB').timezone).to eq('Pending Assignment')
      end

      it 'sends P&C an email with new items to update' do
        adp.sync_locations
        expect(PeopleAndCultureMailer).to have_received(:code_list_alert)
      end

      it 'creates the global groups in AD' do
        adp.sync_locations
        expect(service).to have_received(:new_group).with('AB', 'Geographic')
      end
    end

    context 'with existing locations' do
      let(:adp) { AdpService::CodeLists.new }
      let!(:location) do
        FactoryGirl.create(:location,
          code: 'AB',
          name: 'Alberta',
          status: 'Active',
          kind: 'Remote Location',
          timezone: '(GMT-07:00) Mountain Time (US & Canada)')
      end

      before do
        adp.token = 'a-token-value'
        allow(response).to receive(:body)
          .and_return('{"codeLists":[{"codeListTitle":"locations","listItems":[{"valueDescription":"AB - Alberta", "codeValue":"AB", "shortName":"New Alberta"}, {"valueDescription":"AZ - Arizona", "codeValue":"AZ", "shortName":"Arizona"}, {"valueDescription":"BC - British Columbia", "codeValue":"BC", "shortName":"British Columbia"}, {"valueDescription":"BER - Berlin", "codeValue":"BER", "shortName":"Berlin"}, {"valueDescription":"BM - Birmingham", "codeValue":"BM", "shortName":"Birmingham"}]}]}')
        adp.sync_locations
      end

      it 'updates location name' do
        expect(location.reload.name).to eq('New Alberta')
      end

      it 'does not update country' do
        expect(location.reload.address.country.iso_alpha_2).to eq('US')
      end

      it 'does not update timezone' do
        expect(location.timezone).to eq('(GMT-07:00) Mountain Time (US & Canada)')
      end
    end

    context 'when location is deactivated in adp' do
      let(:adp) { AdpService::CodeLists.new }
      let!(:chattanooga) do
        Location.find_or_create_by(code: 'CHA',
          name: 'Chattanooga',
          status: 'Active')
      end
      let!(:alberta) do
        Location.find_or_create_by(code: 'AB',
          name: 'Alberta',
          status: 'Active')
      end

      before do
        adp.token = 'a-token-value'
        allow(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"locations","listItems":[{"valueDescription":"AB - Alberta", "codeValue":"AB", "shortName":"New Alberta"}, {"valueDescription":"AZ - Arizona", "codeValue":"AZ", "shortName":"Arizona"}, {"valueDescription":"BC - British Columbia", "codeValue":"BC", "shortName":"British Columbia"}, {"valueDescription":"BER - Berlin", "codeValue":"BER", "shortName":"Berlin"}, {"valueDescription":"BM - Birmingham", "codeValue":"BM", "shortName":"Birmingham"}]}]}')
        adp.sync_locations
      end

      it 'assigns status inactive for deactivated location' do
        expect(chattanooga.reload.status).to eq('Inactive')
      end

      it 'assigns status active for active locations' do
        expect(alberta.reload.status).to eq('Active')
      end
    end

  end

  describe '#sync_departments' do
    let(:adp)     { AdpService::CodeLists.new }

    before do
      Department.destroy_all
      adp.token = "a-token-value"
      allow(URI).to receive(:parse).with("https://api.adp.com/codelists/hr/v3/worker-management/departments/WFN/1").and_return(uri)
      allow(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
      allow(response).to receive(:code)
      allow(response).to receive(:message)
      allow(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"departments","listItems":[{"valueDescription":"010000 - Facilities", "foreignKey":"WP8", "codeValue":"010000", "shortName":"Facilities"},{"valueDescription":"011000 - People & Culture-HR & Total Rewards", "foreignKey":"WP8", "codeValue":"011000", "longName":"People & Culture-HR & Total Rewards"},{"valueDescription":"012000 - Legal", "foreignKey":"WP8", "codeValue":"012000", "shortName":"Legal"},{"valueDescription":"013000 - Finance", "foreignKey":"WP8", "codeValue":"013000", "shortName":"Finance"},{"valueDescription":"014000 - Risk Management", "foreignKey":"WP8", "codeValue":"014000", "shortName":"Risk Management"}]}]}')
      allow(PeopleAndCultureMailer).to receive_message_chain(:code_list_alert, :deliver_now)
    end

    context 'with new department' do
      it 'creates new department records' do
        expect{
          adp.sync_departments
        }.to change{ Department.count }.from(0).to(5)
      end

      it 'does not assign a parent org' do
        adp.sync_departments
        expect(Department.find_by(code: '010000').parent_org_id).to eq(nil)
      end

      it 'sends p&c an email alert' do
        adp.sync_departments
        expect(PeopleAndCultureMailer).to have_received(:code_list_alert)
      end

      it 'creates the global groups in AD' do
        adp.sync_departments
        expect(service).to have_received(:new_group).with('010000', 'Department')
      end
    end

    context 'with existing departments' do
      let(:parent_org) { FactoryGirl.create(:parent_org, code: 'xx') }
      let!(:department) do
        Department.find_or_create_by(
          code: '010000',
          name: 'Facilities',
          status: 'Active',
          parent_org: parent_org)
      end
      let!(:old_department) do
        Department.find_or_create_by(
          code: 'xxx',
          name: 'old',
          status: 'Active',
          parent_org: parent_org)
      end

      before do
        adp.token = 'a-token-value'
        allow(response).to receive(:body)
          .and_return('{"codeLists":[{"codeListTitle":"departments","listItems":[{"valueDescription":"010000 - Facilities", "foreignKey":"WP8", "codeValue":"010000", "shortName":"New Facilities"},{"valueDescription":"011000 - People & Culture-HR & Total Rewards", "foreignKey":"WP8", "codeValue":"011000", "longName":"People & Culture-HR & Total Rewards"},{"valueDescription":"012000 - Legal", "foreignKey":"WP8", "codeValue":"012000", "shortName":"Legal"},{"valueDescription":"013000 - Finance", "foreignKey":"WP8", "codeValue":"013000", "shortName":"Finance"},{"valueDescription":"014000 - Risk Management", "foreignKey":"WP8", "codeValue":"014000", "shortName":"Risk Management"}]}]}')
        adp.sync_departments
      end

      it 'updates department name' do
        expect(department.reload.name).to eq('New Facilities')
      end

      it 'does not update parent org' do
        expect(department.parent_org_id).to eq(parent_org.id)
      end

      it 'assigns status as active' do
        expect(department.status).to eq('Active')
      end

      it 'leaves status as inactive for deactivated department' do
        expect(old_department.reload.status).to eq('Inactive')
      end
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
      expect(response).to receive(:code)
      expect(response).to receive(:message)
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
