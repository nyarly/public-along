require 'rails_helper'

describe AdpService::WorkerJsonParser, type: :service do
  let(:json) { JSON.parse(File.read(Rails.root.to_s+"/spec/fixtures/adp_workers.json")) }

  describe "sort_workers" do

    it "should call gen_worker_hash if not terminated status" do
      # There are 3 workers indicated in the json file, one is terminated

      adp = AdpService::WorkerJsonParser.new

      expect(adp).to receive(:gen_worker_hash).exactly(2).times
      adp.sort_workers(json)
    end

    it "should return worker array" do
      adp = AdpService::WorkerJsonParser.new

      expect(adp).to receive(:gen_worker_hash).twice.and_return({worker: "info"})
      expect(adp.sort_workers(json)).to eq([{worker: "info"}, {worker: "info"}])
    end
  end

  describe "gen_worker_hash" do
    let(:json)           { JSON.parse(File.read(Rails.root.to_s+"/spec/fixtures/adp_workers.json")) }
    let!(:manager)       { FactoryGirl.create(:active_profile, adp_employee_id: "101734") }
    let!(:worker_type)   { FactoryGirl.create(:worker_type, name: "Regular Full-Time", code: "FTR") }
    let!(:worker_type_2) { FactoryGirl.create(:worker_type, name: "Voluntary", code: "TVOL") }
    let!(:department)    { FactoryGirl.create(:department, name: "People & Culture-HR & Total Rewards", code: "111000") }
    let!(:department_2)  { FactoryGirl.create(:department, name: "Sales - General - Germany", code: "120710") }
    let!(:department_3)  { FactoryGirl.create(:department, name: "Inside Sales", code: "125000") }
    let!(:location)      { FactoryGirl.create(:location, name: "Las Vegas", code: "LAS") }
    let!(:location_2)    { FactoryGirl.create(:location, name: "Germany", code: "GERMA", kind: "Remote Location") }
    let!(:job_title)     { FactoryGirl.create(:job_title, name: "Sr. People Business Partner", code: "SRBP") }
    let!(:job_title_2)   { FactoryGirl.create(:job_title, name: "Sales Representative, OTC", code: "SROTC") }
    let!(:job_title_3)   { FactoryGirl.create(:job_title, name: "Sales Associate", code: "SADEN") }

    it "should create the hash from json" do
      w_json = json["workers"][2]

      adp = AdpService::WorkerJsonParser.new

      expect(adp.gen_worker_hash(w_json)).to eq({
        status: "active",
        adp_assoc_oid: "G32B8JAXA1W398Z8",
        adp_employee_id: "101455",
        first_name: "Shirley",
        last_name: "Allansberg",
        personal_mobile_phone: "(212) 555-4411",
        office_phone: "(212) 555-4411",
        hire_date: "2013-08-05",
        contract_end_date: nil,
        start_date: "2013-08-05",
        end_date: nil,
        company: "OpenTable Inc.",
        job_title_id: job_title.id,
        worker_type_id: worker_type.id,
        manager_adp_employee_id: "101734",
        location_id: location.id,
        department_id: department.id,
        profile_status: "active",
        business_card_title: "Senior Backend Engineer, Restaurant Products",
        management_position: true,
        manager_id: manager.employee.id
      })
    end

    it "should pick nickname if exists" do
      w_json = json["workers"][0]

      adp = AdpService::WorkerJsonParser.new

      expect(adp.gen_worker_hash(w_json)).to include({
        first_name: "Sally Jesse",
      })
    end

    it "should pick preferred last_name if exists" do
      w_json = json["workers"][0]

      adp = AdpService::WorkerJsonParser.new

      expect(adp.gen_worker_hash(w_json)).to include({
        last_name: "Smith",
      })
    end

    it "should find worker end date if exists" do
      w_json = json["workers"][1]

      adp = AdpService::WorkerJsonParser.new

      expect(adp.gen_worker_hash(w_json)).to include({
        contract_end_date: "2017-01-20"
      })
    end

    it "should find the business card title when given" do
      w_json = json["workers"][2]

      adp = AdpService::WorkerJsonParser.new

      expect(adp.gen_worker_hash(w_json)).to include({
        business_card_title: "Senior Backend Engineer, Restaurant Products"
      })
    end

    it "should use the job title for business card title when not given" do
      w_json = json["workers"][1]

      adp = AdpService::WorkerJsonParser.new

      expect(adp.gen_worker_hash(w_json)).to include({
        business_card_title: "Sales Associate"
      })
    end

    it "should pull address info if the worker is Remote" do
      w_json = json["workers"][0]

      adp = AdpService::WorkerJsonParser.new

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

      adp = AdpService::WorkerJsonParser.new

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
