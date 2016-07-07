require 'rails_helper'

describe XmlService, type: :service do
  let(:xml) { XmlService.new(file) }

  before :each do
    depts = [
      {:name =>  "OT Facilities", :code => "000010"},
      {:name =>  "OT People and Culture", :code => "000011"},
      {:name =>  "OT Legal", :code => "000012"},
      {:name =>  "OT Finance", :code => "000013"},
      {:name =>  "OT Risk Management and Fraud", :code => "000014"},
      {:name =>  "OT Talent Acquisition", :code => "000017"},
      {:name =>  "OT Executive", :code => "000018"},
      {:name =>  "OT Finance Operations", :code => "000019"},
      {:name =>  "OT Sales - General", :code => "000020"},
      {:name =>  "OT Sales Operations", :code => "000021"},
      {:name =>  "OT Inside Sales", :code => "000025"},
      {:name =>  "OT Field Operations", :code => "000031"},
      {:name =>  "OT Customer Support", :code => "000032"},
      {:name =>  "OT Restaurant Relations Management", :code => "000033"},
      {:name =>  "OT IT Technical Services and Helpdesk", :code => "000035"},
      {:name =>  "OT IT - Engineering", :code => "000036"},
      {:name =>  "OT General Engineering", :code => "000040"},
      {:name =>  "OT Consumer Engineering", :code => "000041"},
      {:name =>  "OT Restaurant Engineering", :code => "000042"},
      {:name =>  "OT Data Center Ops", :code => "000043"},
      {:name =>  "OT Business Optimization", :code => "000044"},
      {:name =>  "OT Data Analytics", :code => "000045"},
      {:name =>  "OT General Marketing", :code => "000050"},
      {:name =>  "OT Consumer Marketing", :code => "000051"},
      {:name =>  "OT Restaurant Marketing", :code => "000052"},
      {:name =>  "OT Public Relations", :code => "000053"},
      {:name =>  "OT Product Marketing", :code => "000054"},
      {:name =>  "OT General Product Management", :code => "000060"},
      {:name =>  "OT Restaurant Product Management", :code => "000061"},
      {:name =>  "OT Consumer Product Management", :code => "000062"},
      {:name =>  "OT Design", :code => "000063"},
      {:name =>  "OT Business Development", :code => "000070"}
    ]

    depts.each { |attrs| Department.create(attrs) }

    locs = [
      { :name => "OT San Francisco", :kind => "Office", :country => "US" },
      { :name => "OT Los Angeles", :kind => "Office", :country => "US" },
      { :name => "OT Denver", :kind => "Office", :country => "US" },
      { :name => "OT Chattanooga", :kind => "Office", :country => "US" },
      { :name => "OT Chicago", :kind => "Office", :country => "US" },
      { :name => "OT New York", :kind => "Office", :country => "US" },
      { :name => "OT Mexico City", :kind => "Office", :country => "MX" },
      { :name => "OT London", :kind => "Office", :country => "GB" },
      { :name => "OT Frankfurt", :kind => "Office", :country => "DE" },
      { :name => "OT Mumbai", :kind => "Office", :country => "IN" },
      { :name => "OT Tokyo", :kind => "Office", :country => "JP" },
      { :name => "OT Melbourne", :kind => "Office", :country => "AU" },
      { :name => "OT Arizona", :kind => "Remote Location", :country => "US" },
      { :name => "OT Colorado", :kind => "Remote Location", :country => "US" },
      { :name => "OT Illinois", :kind => "Remote Location", :country => "US" },
      { :name => "OT Tennessee", :kind => "Remote Location", :country => "US" },
      { :name => "OT Southern California", :kind => "Remote Location", :country => "US" },
      { :name => "OT Minnesota", :kind => "Remote Location", :country => "US" },
      { :name => "OT Maine", :kind => "Remote Location", :country => "US" },
      { :name => "OT Georgia", :kind => "Remote Location", :country => "US" },
      { :name => "OT Canada", :kind => "Remote Location", :country => "CA" },
      { :name => "OT Washington DC", :kind => "Remote Location", :country => "US" },
      { :name => "OT Pennsylvania", :kind => "Remote Location", :country => "US" },
      { :name => "OT Oregon", :kind => "Remote Location", :country => "US" },
      { :name => "OT Wisconsin", :kind => "Remote Location", :country => "US" },
      { :name => "OT Texas", :kind => "Remote Location", :country => "US" },
      { :name => "OT Ohio", :kind => "Remote Location", :country => "US" },
      { :name => "OT Massachusetts", :kind => "Remote Location", :country => "US" },
      { :name => "OT Washington", :kind => "Remote Location", :country => "US" },
      { :name => "OT Florida", :kind => "Remote Location", :country => "US" },
      { :name => "OT Nevada", :kind => "Remote Location", :country => "US" },
      { :name => "OT New Jersey", :kind => "Remote Location", :country => "US" },
      { :name => "OT Hawaii", :kind => "Remote Location", :country => "US" },
      { :name => "OT Vermont", :kind => "Remote Location", :country => "US" },
      { :name => "OT Missouri", :kind => "Remote Location", :country => "US" },
      { :name => "OT Louisiana", :kind => "Remote Location", :country => "US" },
      { :name => "OT Michigan", :kind => "Remote Location", :country => "US" },
      { :name => "OT Ireland", :kind => "Remote Location", :country => "IE" },
      { :name => "OT North Carolina", :kind => "Remote Location", :country => "US" },
      { :name => "OT Idaho", :kind => "Remote Location", :country => "US" },
      { :name => "OT Maryland", :kind => "Remote Location", :country => "US" },
      { :name => "OT Utah", :kind => "Remote Location", :country => "US" },
      { :name => "OT Kentucky", :kind => "Remote Location", :country => "US" }
    ]

    locs.each { |attrs| Location.create(attrs) }
  end

  context "New Hire" do
    let(:file) { File.open(Rails.root.to_s+'/spec/fixtures/new_hire.xml') }

    it "should create a new Employee from xml with correct info for a new hire" do
      existing_employee_1 = FactoryGirl.create(:employee, :employee_id => "109640")
      existing_employee_2 = FactoryGirl.create(:employee, :employee_id => "12101234")

      expect{
        xml.parse_to_db
      }.to change{Employee.count}.from(2).to(3)
      expect(Employee.last.first_name).to eq("Jeffrey")
      expect(Employee.last.last_name).to eq("Lebowski")
      expect(Employee.last.workday_username).to eq("jefflebowski")
      expect(Employee.last.employee_id).to eq("12100401")
      expect(Employee.last.location.country).to eq("US")
      expect(Employee.last.hire_date).to eq(DateTime.new(2016,4,25))
      expect(Employee.last.job_family).to eq("OT Internal Systems")
      expect(Employee.last.job_family_id).to eq("OT_Internal_Systems")
      expect(Employee.last.job_profile_id).to eq("50100486")
      expect(Employee.last.job_profile).to eq("OT Internal Systems")
      expect(Employee.last.business_title).to eq("Software Development Team Lead")
      expect(Employee.last.employee_type).to eq("Regular")
      expect(Employee.last.location.kind).to eq("Office")
      expect(Employee.last.location.name).to eq("OT Los Angeles")
      expect(Employee.last.manager_id).to eq("12100123")
      expect(Employee.last.department.name).to eq("OT Business Optimization")
      expect(Employee.last.office_phone).to eq("(213) 555-4321")
      expect(Employee.last.image_code).to be_nil
      expect(Employee.last.home_address_1).to be_nil
      expect(Employee.last.home_address_2).to be_nil
      expect(Employee.last.home_city).to be_nil
      expect(Employee.last.home_state).to be_nil
      expect(Employee.last.home_zip).to be_nil
      expect(Employee.last.ad_updated_at).to be_nil
    end

    it "should have a contract end date for a contingent worker" do
      existing_employee_1 = FactoryGirl.create(:employee, :employee_id => "12100401")
      existing_employee_2 = FactoryGirl.create(:employee, :employee_id => "12101234")

      expect{
        xml.parse_to_db
      }.to change{Employee.count}.from(2).to(3)
      expect(Employee.last.first_name).to eq("Walter")
      expect(Employee.last.last_name).to eq("Sobchak")
      expect(Employee.last.workday_username).to eq("walters")
      expect(Employee.last.employee_id).to eq("109640")
      expect(Employee.last.location.country).to eq("GB")
      expect(Employee.last.hire_date).to eq(DateTime.new(2014,5,2))
      expect(Employee.last.job_family).to eq("OT Contingent Workers")
      expect(Employee.last.job_family_id).to eq("OT_Contingent_Workers")
      expect(Employee.last.job_profile_id).to eq("50100310")
      expect(Employee.last.job_profile).to eq("OT Contingent Worker")
      expect(Employee.last.business_title).to eq("OT Contingent Position - Product Management")
      expect(Employee.last.employee_type).to eq("Vendor")
      expect(Employee.last.location.kind).to eq("Office")
      expect(Employee.last.location.name).to eq("OT London")
      expect(Employee.last.manager_id).to eq("12101502")
      expect(Employee.last.department.name).to eq("OT General Product Management")
      expect(Employee.last.office_phone).to eq("(213) 555-9876")
      expect(Employee.last.image_code).to be_nil
      expect(Employee.last.home_address_1).to be_nil
      expect(Employee.last.home_address_2).to be_nil
      expect(Employee.last.home_city).to be_nil
      expect(Employee.last.home_state).to be_nil
      expect(Employee.last.home_zip).to be_nil
      expect(Employee.last.ad_updated_at).to be_nil
      expect(Employee.last.contract_end_date).to eq(DateTime.new(2016,6,30))
      expect(Employee.last.contingent_worker_type).to eq("Vendor")
      expect(Employee.last.ad_updated_at).to be_nil
    end

    it "should have a home address for a remote worker" do
      existing_employee_1 = FactoryGirl.create(:employee, :employee_id => "12100401")
      existing_employee_2 = FactoryGirl.create(:employee, :employee_id => "109640")

      expect{
        xml.parse_to_db
      }.to change{Employee.count}.from(2).to(3)
      expect(Employee.last.home_address_1).to eq("123 East Side, #2310")
      expect(Employee.last.home_address_2).to be_nil
      expect(Employee.last.home_city).to eq("Chicago")
      expect(Employee.last.home_state).to eq("Illinois")
      expect(Employee.last.home_zip).to eq("60611")
      expect(Employee.last.ad_updated_at).to be_nil
    end

    it "should send an email alert if attributes for employees are invalid" do
      expect(TechTableMailer).to receive_message_chain(:alert_email, :deliver_now)

      xml.parse_to_db
    end
  end

  context "Existing Employee" do
    let(:file) { File.open(Rails.root.to_s+'/spec/fixtures/existing_employee.xml') }
    let!(:employee) { FactoryGirl.create(:employee,
      :employee_id => "12100401",
      :business_title => "Software Development Team Lead",
      :first_name => "Jeffrey",
      :last_name => "Lebowski",
      :department => Department.find_by(:name =>"OT Business Optimization"),
      :image_code => nil)
    }
    let!(:terminated_employee) { FactoryGirl.create(:employee,
      :employee_id => "109843")
    }
    let!(:returning_employee) { FactoryGirl.create(:employee,
      :employee_id => "12100321")
    }
    let!(:previous_leave_emp) { FactoryGirl.create(:employee,
      :employee_id => "1234567",
      :hire_date => DateTime.new(2005, 2, 1),
      :leave_start_date => DateTime.new(2014, 5, 14),
      :leave_return_date => DateTime.new(2014, 6, 14))
    }
    let!(:invalid_emp) { FactoryGirl.create(:employee,
      :employee_id => "12155321")
    }

    it "should update an existing Employee for an existing worker" do
      xml.parse_to_db

      expect(employee.reload.business_title).to eq("Sr. Software Development Team Lead")
      expect(employee.reload.image_code).to eq(IMAGE)
    end

    it "should terminate an existing Employee for an existing worker" do
      xml.parse_to_db

      expect(terminated_employee.reload.termination_date).to eq(DateTime.new(2016,4,27))
    end

    it "should update leave_start_date for Employee going on leave" do
      xml.parse_to_db

      expect(employee.reload.leave_start_date).to eq(DateTime.new(2016,1,16))
      expect(employee.reload.leave_return_date).to be_nil
    end

    it "should update leave_return_date for Employee with known return date" do
      xml.parse_to_db

      expect(returning_employee.reload.leave_start_date).to eq(DateTime.new(2016,1,16))
      expect(returning_employee.reload.leave_return_date).to eq(DateTime.new(2016,5,18))
    end

    it "should use the most recent leave date if the Employee has past leave dates" do
      xml.parse_to_db

      expect(previous_leave_emp.reload.leave_start_date).to eq(DateTime.new(2016,2,28))
      expect(previous_leave_emp.reload.leave_return_date).to eq(DateTime.new(2016,9,28))
    end

    it "should send an email alert if attributes for employees are invalid" do
      expect(TechTableMailer).to receive_message_chain(:alert_email, :deliver_now)

      xml.parse_to_db
    end
  end

  context "parse to Active Directory" do
    let(:file) { File.open(Rails.root.to_s+'/spec/fixtures/new_hire.xml') }
    let!(:emails_xml) { "<?xml version=\"1.0\"?>\n<root>\n  <individual>\n    <identifier>12100401</identifier>\n    <email>jlebowski@opentable.com</email>\n  </individual>\n  <individual>\n    <identifier>12101234</identifier>\n    <email>mlebowski@opentable.com</email>\n  </individual>\n</root>\n" }
    let(:ldap) { double(Net::LDAP) }
    let(:ads) { double(ActiveDirectoryService) }
    let(:http) { double(Net::HTTP) }
    let(:response) { double(Net::HTTPResponse) }

    before :each do
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=).with(true)
      allow(http).to receive(:post).and_return(response)
      allow(response).to receive(:body)
    end

    it "should call active directory to create accounts for all new hires" do
      allow(ActiveDirectoryService).to receive(:new).and_return(ads)

      expect(ads).to receive(:create_disabled_accounts)
      expect(ads).to receive(:update).with([])
      expect{
        xml.parse_to_ad
      }.to change{ Employee.count }.by(3)
    end

    it "should call http service with email xml" do
      allow(Net::LDAP).to receive(:new).and_return(ldap)
      allow(ldap).to receive(:host=)
      allow(ldap).to receive(:port=)
      allow(ldap).to receive(:encryption)
      allow(ldap).to receive(:auth)
      allow(ldap).to receive(:bind)
      allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName
      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)
      allow(ldap).to receive(:add)

      expect(HttpService).to receive(:post_emails).with(SECRETS.xml_post_url, emails_xml)

      xml.parse_to_ad
    end

    it "should call Active Directory to update existing employees" do
      employee1 = FactoryGirl.create(:employee, :employee_id => "12100401")
      employee2 = FactoryGirl.create(:employee, :employee_id => "12101234")

      allow(ActiveDirectoryService).to receive(:new).and_return(ads)
      allow(ads).to receive(:create_disabled_accounts)

      expect(ads).to receive(:update).with([employee1, employee2])
      expect{
        xml.parse_to_ad
      }.to change{ Employee.count }.by(1)
    end

    it "should create an XmlTransaction to record this file as already parsed" do
      allow(ActiveDirectoryService).to receive(:new).and_return(ads)
      allow(ads).to receive(:create_disabled_accounts)
      allow(ads).to receive(:update)

      expect(XmlTransaction).to receive(:create).with({:name=>"new_hire.xml", :checksum=>"b391376cd38195663620209aeca25a10"})

      xml.parse_to_ad
    end
  end
end
