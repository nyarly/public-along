require 'rails_helper'

describe SabaService, type: :service do

  describe "create_org_csv" do
    before :each do
      Department.destroy_all
    end

    let(:service) { SabaService.new }
    let(:parent_org1) { FactoryGirl.create(:parent_org)}
    let!(:dept1) { FactoryGirl.create(:department, parent_org: parent_org1)}
    let(:parent_org2) { FactoryGirl.create(:parent_org)}
    let!(:dept2) { FactoryGirl.create(:department, parent_org: parent_org2)}
    let!(:dept3) { FactoryGirl.create(:department, parent_org: nil)}
    let(:org_csv) {
      <<-EOS.strip_heredoc
      NAME|SPLIT|PARENT_ORG|NAME2|DEFAULT CURRENCY
      #{dept1.code}|OpenTable|#{parent_org1.name}|#{dept1.name}|USD
      #{dept2.code}|OpenTable|#{parent_org2.name}|#{dept2.name}|USD
      #{dept3.code}|OpenTable|OpenTable|#{dept3.name}|USD
      EOS
    }

    it "should output csv string" do
      expect(service.create_org_csv).to eq(org_csv)
    end

    it "should put OpenTable for parent org when a dept has no parent org id" do
      expect(service.create_org_csv).to eq(org_csv)
    end
  end

  describe "create_loc_csv" do
    before :each do
      Location.destroy_all
    end

    let(:service) { SabaService.new }
    let!(:loc1) {FactoryGirl.create(:location,
      status: "Active",
      timezone: "(GMT-07:00) Mountain Time (US & Canada)"
    )}
    let!(:loc2) {FactoryGirl.create(:location,
      status: "Inactive",
      timezone: "(GMT-07:00) Mountain Time (US & Canada)"
    )}
    let(:loc_csv) {
      <<-EOS.strip_heredoc
      LOC_NO|DOMAIN|LOC_NAME|ENABLED|TIMEZONE|PHONE1|ADDR1|ADDR2|CITY|STATE|ZIP|COUNTRY
      #{loc1.code}|OpenTable|#{loc1.name}|TRUE|#{loc1.timezone}|||||||
      #{loc2.code}|OpenTable|#{loc2.name}|FALSE|#{loc2.timezone}|||||||
      EOS
    }

    it "should output csv string" do
      expect(service.create_loc_csv).to eq(loc_csv)
    end

    it "should put TRUE for Active location" do
      expect(service.create_loc_csv).to include(
        "#{loc1.code}|OpenTable|#{loc1.name}|TRUE|#{loc1.timezone}|||||||"
      )
    end

    it "should put FALSE for Inactive location" do
      expect(service.create_loc_csv).to include(
        "#{loc2.code}|OpenTable|#{loc2.name}|FALSE|#{loc1.timezone}|||||||"
      )
    end
  end

  describe "create_job_title_csv" do
    before :each do
      JobTitle.destroy_all
    end

    let(:service) { SabaService.new }
    let!(:job_title1) {FactoryGirl.create(:job_title, status: "Active")}
    let!(:job_title2) {FactoryGirl.create(:job_title, status: "Inactive")}
    let(:jt_csv) {
      <<-EOS.strip_heredoc
      NAME|DOMAIN|JOB_CODE|JOB_FAMILY|STATUS|LOCALE
      #{job_title1.code} - #{job_title1.name}|OpenTable|#{job_title1.code}|All Jobs|100|English
      #{job_title2.code} - #{job_title2.name}|OpenTable|#{job_title2.code}|All Jobs|200|English
      EOS
    }

    it "should output csv string" do
      expect(service.create_job_type_csv).to eq(jt_csv)
    end

    it "should concatenate code and name for NAME column" do
      expect(service.create_job_type_csv).to include("#{job_title1.code} - #{job_title1.name}")
    end

    it "should put 100 for Active, 200 for Inactive" do
      expect(service.create_job_type_csv).to include(
        "#{job_title1.code} - #{job_title1.name}|OpenTable|#{job_title1.code}|All Jobs|100|English"
      )
      expect(service.create_job_type_csv).to include(
        "#{job_title2.code} - #{job_title2.name}|OpenTable|#{job_title2.code}|All Jobs|200|English"
      )
    end
  end

  describe "create_person_csv" do
    before :each do
      Employee.destroy_all
    end

    let(:service) { SabaService.new }
    let(:job_title) { FactoryGirl.create(:job_title)}
    let(:reg_type) { FactoryGirl.create(:worker_type, kind: "Regular")}
    let(:contractor_type) { FactoryGirl.create(:worker_type, kind: "Contractor")}
    let(:loc) { FactoryGirl.create(:location)}
    let(:dept) { FactoryGirl.create(:department)}
    let!(:emp1) {FactoryGirl.create(:employee,
                                    status: "Active",
                                    email: "test1@opentable.com",
                                    job_title_id: job_title.id,
                                    worker_type_id: contractor_type.id,
                                    location_id: loc.id,
                                    department_id: dept.id,
                                    company: "OpenTable, Inc.")}
    let!(:emp2) {FactoryGirl.create(:employee,
                                    status: "Inactive",
                                    email: "test2@opentable.com",
                                    job_title_id: job_title.id,
                                    worker_type_id: reg_type.id,
                                    location_id: loc.id,
                                    department_id: dept.id,
                                    company: "OpenTable, Inc.")}
    let!(:emp3) {FactoryGirl.create(:employee,
                                    status: "Terminated",
                                    email: "test3@opentable.com",
                                    job_title_id: job_title.id,
                                    worker_type_id: reg_type.id,
                                    location_id: loc.id,
                                    department_id: dept.id,
                                    company: "OpenTable, Inc.")}
    let(:person_csv) {
      <<-EOS.strip_heredoc
      PERSON_NO|STATUS|MANAGER|PERSON_TYPE|HIRED_ON|TERMINATED_ON|JOB_TYPE|SECURITY_DOMAIN|RATE|LOCATION|GENDER|HOME_DOMAIN|LOCALE|TIMEZONE|COMPANY|FNAME|LNAME|EMAIL|USERNAME|JOB_TITLE|HOME_COMPANY|CUSTOM0
      #{emp1.employee_id}|Active|#{emp1.manager_id}|#{contractor_type.name}|#{emp1.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable_Contractor|0|#{loc.code}|3|OpenTable_Contractor|English||#{dept.code}|#{emp1.first_name}|#{emp1.last_name}|#{emp1.email}|#{emp1.email}|#{job_title.name}|#{dept.code}|#{emp1.company}
      #{emp2.employee_id}|Leave|#{emp2.manager_id}|#{contractor_type.name}|#{emp2.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp2.first_name}|#{emp2.last_name}|#{emp2.email}|#{emp2.email}|#{job_title.name}|#{dept.code}|#{emp2.company}
      #{emp3.employee_id}|Terminated|#{emp3.manager_id}|#{contractor_type.name}|#{emp3.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp3.first_name}|#{emp3.last_name}|#{emp3.email}|#{emp3.email}|#{job_title.name}|#{dept.code}|#{emp3.company}
      EOS
    }

    it "should output csv string" do
      expect(service.create_person_csv).to eq(person_csv)
    end

    it "should put Leave if status is Inactive otherwise use status value" do
      expect(service.create_person_csv).to include(
        "#{emp2.employee_id}|Leave|#{emp2.manager_id}|#{contractor_type.name}|#{emp2.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp2.first_name}|#{emp2.last_name}|#{emp2.email}|#{emp2.email}|#{job_title.name}|#{dept.code}|#{emp2.company}"
      )
      expect(service.create_person_csv).to include(
        "#{emp1.employee_id}|Active|#{emp1.manager_id}|#{contractor_type.name}|#{emp1.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable_Contractor|0|#{loc.code}|3|OpenTable_Contractor|English||#{dept.code}|#{emp1.first_name}|#{emp1.last_name}|#{emp1.email}|#{emp1.email}|#{job_title.name}|#{dept.code}|#{emp1.company}"
      )
      expect(service.create_person_csv).to include(
        "#{emp3.employee_id}|Terminated|#{emp3.manager_id}|#{contractor_type.name}|#{emp3.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp3.first_name}|#{emp3.last_name}|#{emp3.email}|#{emp3.email}|#{job_title.name}|#{dept.code}|#{emp3.company}"
      )
    end

    it "should assign OpenTable_Contractor for HOME/SECURITY DOMAIN if contractor type" do
      expect(service.create_person_csv).to include(
        "#{emp1.employee_id}|Active|#{emp1.manager_id}|#{contractor_type.name}|#{emp1.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable_Contractor|0|#{loc.code}|3|OpenTable_Contractor|English||#{dept.code}|#{emp1.first_name}|#{emp1.last_name}|#{emp1.email}|#{emp1.email}|#{job_title.name}|#{dept.code}|#{emp1.company}"
      )
    end

    it "should assign OpenTable for HOME/SECURITY DOMAIN if not contractor type" do
      expect(service.create_person_csv).to include(
        "#{emp2.employee_id}|Leave|#{emp2.manager_id}|#{contractor_type.name}|#{emp2.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp2.first_name}|#{emp2.last_name}|#{emp2.email}|#{emp2.email}|#{job_title.name}|#{dept.code}|#{emp2.company}"
      )
    end
  end
end
