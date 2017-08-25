require 'rails_helper'

describe SabaService, type: :service do
  before :each do
    Dir["tmp/saba/*"].each do |f|
      File.delete(f)
    end

    dirname = 'tmp/saba'
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
  end

  after :each do
    Dir["tmp/saba/*"].each do |f|
      File.delete(f)
    end
  end


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
      NAME|SPLIT|PARENT_ORG|NAME2|DEFAULT_CURRENCY
      #{dept1.code}|OpenTable|#{parent_org1.code}|#{dept1.name}|USD
      #{dept2.code}|OpenTable|#{parent_org2.code}|#{dept2.name}|USD
      #{dept3.code}|OpenTable|OPENTABLE|#{dept3.name}|USD
      #{parent_org1.code}|OpenTable|OPENTABLE|#{parent_org1.name}|USD
      #{parent_org2.code}|OpenTable|OPENTABLE|#{parent_org2.name}|USD
      EOS
    }
    let(:filepath) { Rails.root.to_s+"/tmp/saba/organization_#{DateTime.now.strftime('%Y%m%d')}.csv" }

    it "should output csv string" do
      service.create_org_csv

      expect(File.read(filepath)).to eq(org_csv)
    end

    it "should put OPENTABLE for parent org when a dept has no parent org id" do
      service.create_org_csv

      expect(File.read(filepath)).to include("#{dept3.code}|OpenTable|OPENTABLE|#{dept3.name}|USD")
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
    let(:filepath) { Rails.root.to_s+"/tmp/saba/location_#{DateTime.now.strftime('%Y%m%d')}.csv" }

    it "should output csv string" do
      service.create_loc_csv

      expect(File.read(filepath)).to eq(loc_csv)
    end

    it "should put TRUE for Active location" do
      service.create_loc_csv

      expect(File.read(filepath)).to include(
        "#{loc1.code}|OpenTable|#{loc1.name}|TRUE|#{loc1.timezone}|||||||"
      )
    end

    it "should put FALSE for Inactive location" do
      service.create_loc_csv

      expect(File.read(filepath)).to include(
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
    let(:filepath) { Rails.root.to_s+"/tmp/saba/jobtype_#{DateTime.now.strftime('%Y%m%d')}.csv" }

    it "should output csv string" do
      service.create_job_type_csv
      expect(File.read(filepath)).to eq(jt_csv)
    end

    it "should concatenate code and name for NAME column" do
      service.create_job_type_csv
      expect(File.read(filepath)).to include("#{job_title1.code} - #{job_title1.name}")
    end

    it "should put 100 for Active, 200 for Inactive" do
      service.create_job_type_csv
      expect(File.read(filepath)).to include(
        "#{job_title1.code} - #{job_title1.name}|OpenTable|#{job_title1.code}|All Jobs|100|English"
      )
      expect(File.read(filepath)).to include(
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
      email: "test1@opentable.com")}
    let!(:profile_1) { FactoryGirl.create(:profile,
      employee: emp1,
      profile_status: "Active",
      job_title_id: job_title.id,
      worker_type_id: contractor_type.id,
      location_id: loc.id,
      department_id: dept.id,
      company: "OpenTable, Inc.")}
    let!(:emp2) {FactoryGirl.create(:employee,
      status: "Inactive",
      email: "test2@opentable.com")}
    let!(:profile_2) { FactoryGirl.create(:profile,
      employee: emp2,
      profile_status: "Active",
      job_title_id: job_title.id,
      worker_type_id: reg_type.id,
      location_id: loc.id,
      department_id: dept.id,
      company: "OpenTable, Inc.")}
    let!(:emp3) {FactoryGirl.create(:employee,
      status: "Terminated",
      email: "test3@opentable.com")}
    let!(:profile_3) { FactoryGirl.create(:profile,
      employee: emp3,
      profile_status: "Terminated",
      job_title_id: job_title.id,
      worker_type_id: reg_type.id,
      location_id: loc.id,
      department_id: dept.id,
      company: "OpenTable, Inc.")}
    let!(:emp4) {FactoryGirl.create(:employee,
      status: "Pending",
      email: "test4@opentable.com")}
    let!(:profile_4) { FactoryGirl.create(:profile,
      employee: emp4,
      profile_status: "Pending",
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
      #{emp4.employee_id}|Active|#{emp4.manager_id}|#{contractor_type.name}|#{emp4.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp4.first_name}|#{emp4.last_name}|#{emp4.email}|#{emp4.email}|#{job_title.name}|#{dept.code}|#{emp4.company}
      EOS
    }
    let(:person_uat_csv) {
      <<-EOS.strip_heredoc
      PERSON_NO|STATUS|MANAGER|PERSON_TYPE|HIRED_ON|TERMINATED_ON|JOB_TYPE|SECURITY_DOMAIN|RATE|LOCATION|GENDER|HOME_DOMAIN|LOCALE|TIMEZONE|COMPANY|FNAME|LNAME|EMAIL|USERNAME|JOB_TITLE|HOME_COMPANY|CUSTOM0
      #{emp1.employee_id}|Active|#{emp1.manager_id}|#{contractor_type.name}|#{emp1.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable_Contractor|0|#{loc.code}|3|OpenTable_Contractor|English||#{dept.code}|#{emp1.first_name}|#{emp1.last_name}||#{emp1.email}|#{job_title.name}|#{dept.code}|#{emp1.company}
      #{emp2.employee_id}|Leave|#{emp2.manager_id}|#{contractor_type.name}|#{emp2.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp2.first_name}|#{emp2.last_name}||#{emp2.email}|#{job_title.name}|#{dept.code}|#{emp2.company}
      #{emp3.employee_id}|Terminated|#{emp3.manager_id}|#{contractor_type.name}|#{emp3.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp3.first_name}|#{emp3.last_name}||#{emp3.email}|#{job_title.name}|#{dept.code}|#{emp3.company}
      #{emp4.employee_id}|Active|#{emp4.manager_id}|#{contractor_type.name}|#{emp4.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp4.first_name}|#{emp4.last_name}||#{emp4.email}|#{job_title.name}|#{dept.code}|#{emp4.company}
      EOS
    }
    let(:filepath) { Rails.root.to_s+"/tmp/saba/person_#{DateTime.now.strftime('%Y%m%d')}.csv" }

    describe "prod saba" do
      before :each do
        allow(Rails.application.secrets).to receive(:saba_sftp_path).and_return('/opentable/production/inbound')
      end

      it "should output csv string" do
        service.create_person_csv

        expect(File.read(filepath)).to eq(person_csv)
      end

      it "should assign the correct status value" do
        service.create_person_csv

        expect(File.read(filepath)).to include(
          "#{emp2.employee_id}|Leave|#{emp2.manager_id}|#{contractor_type.name}|#{emp2.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp2.first_name}|#{emp2.last_name}|#{emp2.email}|#{emp2.email}|#{job_title.name}|#{dept.code}|#{emp2.company}"
        )
        expect(File.read(filepath)).to include(
          "#{emp1.employee_id}|Active|#{emp1.manager_id}|#{contractor_type.name}|#{emp1.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable_Contractor|0|#{loc.code}|3|OpenTable_Contractor|English||#{dept.code}|#{emp1.first_name}|#{emp1.last_name}|#{emp1.email}|#{emp1.email}|#{job_title.name}|#{dept.code}|#{emp1.company}"
        )
        expect(File.read(filepath)).to include(
          "#{emp3.employee_id}|Terminated|#{emp3.manager_id}|#{contractor_type.name}|#{emp3.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp3.first_name}|#{emp3.last_name}|#{emp3.email}|#{emp3.email}|#{job_title.name}|#{dept.code}|#{emp3.company}"
        )
        expect(File.read(filepath)).to include(
          "#{emp4.employee_id}|Active|#{emp4.manager_id}|#{contractor_type.name}|#{emp4.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp4.first_name}|#{emp4.last_name}|#{emp4.email}|#{emp4.email}|#{job_title.name}|#{dept.code}|#{emp4.company}"
        )
      end

      it "should assign OpenTable_Contractor for HOME/SECURITY DOMAIN if contractor type" do
        service.create_person_csv

        expect(File.read(filepath)).to include(
          "#{emp1.employee_id}|Active|#{emp1.manager_id}|#{contractor_type.name}|#{emp1.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable_Contractor|0|#{loc.code}|3|OpenTable_Contractor|English||#{dept.code}|#{emp1.first_name}|#{emp1.last_name}|#{emp1.email}|#{emp1.email}|#{job_title.name}|#{dept.code}|#{emp1.company}"
        )
      end

      it "should assign OpenTable for HOME/SECURITY DOMAIN if not contractor type" do
        service.create_person_csv

        expect(File.read(filepath)).to include(
          "#{emp2.employee_id}|Leave|#{emp2.manager_id}|#{contractor_type.name}|#{emp2.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp2.first_name}|#{emp2.last_name}|#{emp2.email}|#{emp2.email}|#{job_title.name}|#{dept.code}|#{emp2.company}"
        )
      end
    end

    describe "staging saba" do
      before :each do
        allow(Rails.application.secrets).to receive(:saba_sftp_path).and_return('/opentable/uat/inbound')
      end

      it "should not include email column if path is uat" do
        service.create_person_csv

        expect(File.read(filepath)).to eq(person_uat_csv)
      end
    end
  end

  describe "generate_csvs" do
    let(:service) { SabaService.new }

    it "makes the correct number of csvs" do
      expect{
        service.generate_csvs
      }.to change{Dir["tmp/saba/*"].count}.from(0).to(4)
    end
  end
end
