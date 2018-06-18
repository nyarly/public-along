require 'rails_helper'

describe SabaService, type: :service do
  before do
    Dir['tmp/saba/*'].each do |f|
      File.delete(f)
    end

    dirname = 'tmp/saba'
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
  end

  after do
    Dir['tmp/saba/*'].each do |f|
      File.delete(f)
    end
  end

  describe '#create_org_csv' do
    let(:service)   { SabaService.new }
    let(:filepath)  { Rails.root.to_s + "/tmp/saba/organization_#{DateTime.now.strftime('%Y%m%d')}.csv" }

    before do
      Department.destroy_all
    end

    let(:parent_org1) { FactoryGirl.create(:parent_org) }
    let!(:dept1)      { FactoryGirl.create(:department, parent_org: parent_org1) }
    let(:parent_org2) { FactoryGirl.create(:parent_org) }
    let!(:dept2)      { FactoryGirl.create(:department, parent_org: parent_org2) }
    let!(:dept3)      { FactoryGirl.create(:department, parent_org: nil) }
    let(:org_csv) do
      <<-EOS.strip_heredoc
      NAME|SPLIT|PARENT_ORG|NAME2|DEFAULT_CURRENCY
      #{dept1.code}|OpenTable|#{parent_org1.code}|#{dept1.name}|USD
      #{dept2.code}|OpenTable|#{parent_org2.code}|#{dept2.name}|USD
      #{dept3.code}|OpenTable|OPENTABLE|#{dept3.name}|USD
      #{parent_org1.code}|OpenTable|OPENTABLE|#{parent_org1.name}|USD
      #{parent_org2.code}|OpenTable|OPENTABLE|#{parent_org2.name}|USD
      EOS
    end

    it 'outputs csv string' do
      service.create_org_csv

      expect(File.read(filepath)).to eq(org_csv)
    end

    it 'has OPENTABLE for parent org when a dept has no parent org id' do
      service.create_org_csv

      expect(File.read(filepath)).to include("#{dept3.code}|OpenTable|OPENTABLE|#{dept3.name}|USD")
    end
  end

  describe '#create_loc_csv' do
    let(:service)   { SabaService.new }
    let(:filepath)  { Rails.root.to_s + "/tmp/saba/location_#{DateTime.now.strftime('%Y%m%d')}.csv" }

    before do
      Location.destroy_all
    end

    let!(:loc1) do
      FactoryGirl.create(:location,
        status: 'Active',
        timezone: '(GMT-07:00) Mountain Time (US & Canada)')
    end
    let!(:loc2) do
      FactoryGirl.create(:location,
        status: 'Inactive',
        timezone: '(GMT-07:00) Mountain Time (US & Canada)')
    end
    let(:loc_csv) do
      <<-EOS.strip_heredoc
      LOC_NO|DOMAIN|LOC_NAME|ENABLED|TIMEZONE|PHONE1|ADDR1|ADDR2|CITY|STATE|ZIP|COUNTRY
      #{loc1.code}|OpenTable|#{loc1.name}|TRUE|#{loc1.timezone}|||||||
      #{loc2.code}|OpenTable|#{loc2.name}|FALSE|#{loc2.timezone}|||||||
      EOS
    end

    it 'outputs csv string' do
      service.create_loc_csv

      expect(File.read(filepath)).to eq(loc_csv)
    end

    it 'has TRUE for active location' do
      service.create_loc_csv

      expect(File.read(filepath)).to include(
        "#{loc1.code}|OpenTable|#{loc1.name}|TRUE|#{loc1.timezone}|||||||"
      )
    end

    it 'has FALSE for Inactive location' do
      service.create_loc_csv

      expect(File.read(filepath)).to include(
        "#{loc2.code}|OpenTable|#{loc2.name}|FALSE|#{loc1.timezone}|||||||"
      )
    end
  end

  describe '#create_job_title_csv' do
    before do
      JobTitle.destroy_all
    end

    let(:service)     { SabaService.new }
    let!(:job_title1) { FactoryGirl.create(:job_title, status: 'Active') }
    let!(:job_title2) { FactoryGirl.create(:job_title, status: 'Inactive') }
    let(:jt_csv) do
      <<-EOS.strip_heredoc
      NAME|DOMAIN|JOB_CODE|JOB_FAMILY|STATUS|LOCALE
      #{job_title1.code} - #{job_title1.name}|OpenTable|#{job_title1.code}|All Jobs|100|English
      #{job_title2.code} - #{job_title2.name}|OpenTable|#{job_title2.code}|All Jobs|200|English
      EOS
    end
    let(:filepath) { Rails.root.to_s + "/tmp/saba/jobtype_#{DateTime.now.strftime('%Y%m%d')}.csv" }

    it 'outputs csv string' do
      service.create_job_type_csv
      expect(File.read(filepath)).to eq(jt_csv)
    end

    it 'concatenates code and name for NAME column' do
      service.create_job_type_csv
      expect(File.read(filepath)).to include("#{job_title1.code} - #{job_title1.name}")
    end

    it 'has 100 for Active, 200 for Inactive' do
      service.create_job_type_csv
      expect(File.read(filepath)).to include(
        "#{job_title1.code} - #{job_title1.name}|OpenTable|#{job_title1.code}|All Jobs|100|English"
      )
      expect(File.read(filepath)).to include(
        "#{job_title2.code} - #{job_title2.name}|OpenTable|#{job_title2.code}|All Jobs|200|English"
      )
    end
  end

  describe '#create_person_csv' do
    let(:service)   { SabaService.new }
    let(:filepath)  { Rails.root.to_s + "/tmp/saba/person_#{DateTime.now.strftime('%Y%m%d')}.csv" }

    before do
      Employee.destroy_all
    end

    let(:dept)            { FactoryGirl.create(:department) }
    let(:loc)             { FactoryGirl.create(:location) }
    let(:job_title)       { FactoryGirl.create(:job_title) }
    let(:biz_unit)        { FactoryGirl.create(:business_unit) }
    let(:reg_type)        { FactoryGirl.create(:worker_type, kind: "Regular") }
    let(:contractor_type) { FactoryGirl.create(:worker_type, kind: "Contractor") }
    let(:emp1) do
      FactoryGirl.create(:active_profile,
        worker_type: contractor_type,
        department: dept,
        location: loc,
        job_title: job_title,
        business_unit: biz_unit,
        adp_employee_id: "112233",
        employee_args: {
         last_name: "Aaa",
         email: "test1@opentable.com",
         status: "active" })
    end
    let!(:emp2) do
      FactoryGirl.create(:leave_profile,
        worker_type: reg_type,
        department: dept,
        location: loc,
        job_title: job_title,
        business_unit: biz_unit,
        employee_args: {
          last_name: "Bbb",
          email: "test2@opentable.com",
          status: "inactive",
          manager: emp1.employee })
    end
    let!(:emp3) do
      FactoryGirl.create(:terminated_profile,
        worker_type: reg_type,
        department: dept,
        location: loc,
        job_title: job_title,
        business_unit: biz_unit,
        employee_args: {
          last_name: "Ccc",
          email: "test3@opentable.com",
          status: "terminated",
          manager: emp1.employee })
    end
    let!(:emp4) do
      FactoryGirl.create(:profile,
        worker_type: reg_type,
        department: dept,
        location: loc,
        job_title: job_title,
        business_unit: biz_unit,
        employee_args: {
          last_name: "Ddd",
          email: "test4@opentable.com",
          status: "pending",
          manager: emp1.employee })
    end

    let(:person_csv) do
      <<-EOS.strip_heredoc
      PERSON_NO|STATUS|MANAGER|PERSON_TYPE|HIRED_ON|TERMINATED_ON|JOB_TYPE|SECURITY_DOMAIN|RATE|LOCATION|GENDER|HOME_DOMAIN|LOCALE|TIMEZONE|COMPANY|FNAME|LNAME|EMAIL|USERNAME|JOB_TITLE|HOME_COMPANY|CUSTOM0
      #{emp1.employee.employee_id}|active||#{contractor_type.name}|#{emp1.employee.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable_Contractor|0|#{loc.code}|3|OpenTable_Contractor|English||#{dept.code}|#{emp1.employee.first_name}|#{emp1.employee.last_name}|#{emp1.employee.email}|#{emp1.employee.email}|#{job_title.name}|#{dept.code}|#{biz_unit.name}
      #{emp2.employee.employee_id}|leave|#{emp2.employee.manager.employee_id}|#{contractor_type.name}|#{emp2.employee.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp2.employee.first_name}|#{emp2.employee.last_name}|#{emp2.employee.email}|#{emp2.employee.email}|#{job_title.name}|#{dept.code}|#{biz_unit.name}
      #{emp3.employee.employee_id}|terminated|#{emp3.employee.manager.employee_id}|#{contractor_type.name}|#{emp3.employee.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp3.employee.first_name}|#{emp3.employee.last_name}|#{emp3.employee.email}|#{emp3.employee.email}|#{job_title.name}|#{dept.code}|#{biz_unit.name}
      #{emp4.employee.employee_id}|active|#{emp4.employee.manager.employee_id}|#{contractor_type.name}|#{emp4.employee.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp4.employee.first_name}|#{emp4.employee.last_name}|#{emp4.employee.email}|#{emp4.employee.email}|#{job_title.name}|#{dept.code}|#{biz_unit.name}
      EOS
    end
    let(:person_uat_csv) {
      <<-EOS.strip_heredoc
      PERSON_NO|STATUS|MANAGER|PERSON_TYPE|HIRED_ON|TERMINATED_ON|JOB_TYPE|SECURITY_DOMAIN|RATE|LOCATION|GENDER|HOME_DOMAIN|LOCALE|TIMEZONE|COMPANY|FNAME|LNAME|EMAIL|USERNAME|JOB_TITLE|HOME_COMPANY|CUSTOM0
      #{emp1.employee.employee_id}|active||#{contractor_type.name}|#{emp1.employee.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable_Contractor|0|#{loc.code}|3|OpenTable_Contractor|English||#{dept.code}|#{emp1.employee.first_name}|#{emp1.employee.last_name}||#{emp1.employee.email}|#{job_title.name}|#{dept.code}|#{biz_unit.name}
      #{emp2.employee.employee_id}|leave|#{emp2.employee.manager.employee_id}|#{contractor_type.name}|#{emp2.employee.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp2.employee.first_name}|#{emp2.employee.last_name}||#{emp2.employee.email}|#{job_title.name}|#{dept.code}|#{biz_unit.name}
      #{emp3.employee.employee_id}|terminated|#{emp3.employee.manager.employee_id}|#{contractor_type.name}|#{emp3.employee.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp3.employee.first_name}|#{emp3.employee.last_name}||#{emp3.employee.email}|#{job_title.name}|#{dept.code}|#{biz_unit.name}
      #{emp4.employee.employee_id}|active|#{emp4.employee.manager.employee_id}|#{contractor_type.name}|#{emp4.employee.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp4.employee.first_name}|#{emp4.employee.last_name}||#{emp4.employee.email}|#{job_title.name}|#{dept.code}|#{biz_unit.name}
      EOS
    }

    context 'when production' do
      before do
        allow(Rails.application.secrets).to receive(:saba_sftp_path).and_return('/opentable/production/inbound')
      end

      it 'outputs csv string' do
        service.create_person_csv

        expect(File.read(filepath)).to eq(person_csv)
      end

      it "should assign the correct status value" do
        service.create_person_csv

        expect(File.read(filepath)).to include(
          "#{emp2.employee.employee_id}|leave|#{emp2.employee.manager.employee_id}|#{contractor_type.name}|#{emp2.employee.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp2.employee.first_name}|#{emp2.employee.last_name}|#{emp2.employee.email}|#{emp2.employee.email}|#{job_title.name}|#{dept.code}|#{biz_unit.name}"
        )
        expect(File.read(filepath)).to include(
          "#{emp1.employee.employee_id}|active||#{contractor_type.name}|#{emp1.employee.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable_Contractor|0|#{loc.code}|3|OpenTable_Contractor|English||#{dept.code}|#{emp1.employee.first_name}|#{emp1.employee.last_name}|#{emp1.employee.email}|#{emp1.employee.email}|#{job_title.name}|#{dept.code}|#{biz_unit.name}"
        )
        expect(File.read(filepath)).to include(
          "#{emp3.employee.employee_id}|terminated|#{emp3.employee.manager.employee_id}|#{contractor_type.name}|#{emp3.employee.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp3.employee.first_name}|#{emp3.employee.last_name}|#{emp3.employee.email}|#{emp3.employee.email}|#{job_title.name}|#{dept.code}|#{biz_unit.name}"
        )
        expect(File.read(filepath)).to include(
          "#{emp4.employee.employee_id}|active|#{emp4.employee.manager.employee_id}|#{contractor_type.name}|#{emp4.employee.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp4.employee.first_name}|#{emp4.employee.last_name}|#{emp4.employee.email}|#{emp4.employee.email}|#{job_title.name}|#{dept.code}|#{biz_unit.name}"
        )
      end

      it "should assign OpenTable_Contractor for HOME/SECURITY DOMAIN if contractor type" do
        service.create_person_csv

        expect(File.read(filepath)).to include(
          "#{emp1.employee.employee_id}|active||#{contractor_type.name}|#{emp1.employee.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable_Contractor|0|#{loc.code}|3|OpenTable_Contractor|English||#{dept.code}|#{emp1.employee.first_name}|#{emp1.employee.last_name}|#{emp1.employee.email}|#{emp1.employee.email}|#{job_title.name}|#{dept.code}|#{biz_unit.name}"
        )
      end

      it "should assign OpenTable for HOME/SECURITY DOMAIN if not contractor type" do
        service.create_person_csv

        expect(File.read(filepath)).to include(
          "#{emp2.employee.employee_id}|leave|#{emp2.employee.manager.employee_id}|#{contractor_type.name}|#{emp2.employee.hire_date.strftime("%Y-%m-%d")}||#{job_title.code}|OpenTable|0|#{loc.code}|3|OpenTable|English||#{dept.code}|#{emp2.employee.first_name}|#{emp2.employee.last_name}|#{emp2.employee.email}|#{emp2.employee.email}|#{job_title.name}|#{dept.code}|#{biz_unit.name}"
        )
      end
    end

    context 'when staging' do
      before do
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
