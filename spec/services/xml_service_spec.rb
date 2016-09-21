require 'rails_helper'

describe XmlService, type: :service do
  let(:xml) { XmlService.new(file) }

  context "New Hire" do
    let(:file) { File.open(Rails.root.to_s+'/spec/fixtures/new_hire.xml') }
    let(:mailer) { double(ManagerMailer) }

    it "should create a new Employee from xml with correct info for a new hire" do
      existing_employee_1 = FactoryGirl.create(:employee, :employee_id => "109640")
      existing_employee_2 = FactoryGirl.create(:employee, :employee_id => "12101234")

      expect{
        xml.parse_to_db
      }.to change{Employee.count}.from(2).to(3)
      expect(Employee.find_by(:first_name => "Jeffrey").first_name).to eq("Jeffrey")
      expect(Employee.find_by(:first_name => "Jeffrey").last_name).to eq("Lebowski")
      expect(Employee.find_by(:first_name => "Jeffrey").workday_username).to eq("jefflebowski")
      expect(Employee.find_by(:first_name => "Jeffrey").employee_id).to eq("12100401")
      expect(Employee.find_by(:first_name => "Jeffrey").location.country).to eq("US")
      expect(Employee.find_by(:first_name => "Jeffrey").hire_date).to eq(DateTime.new(2016,4,25))
      expect(Employee.find_by(:first_name => "Jeffrey").job_family).to eq("OT Internal Systems")
      expect(Employee.find_by(:first_name => "Jeffrey").job_family_id).to eq("OT_Internal_Systems")
      expect(Employee.find_by(:first_name => "Jeffrey").job_profile_id).to eq("50100486")
      expect(Employee.find_by(:first_name => "Jeffrey").job_profile).to eq("OT Internal Systems")
      expect(Employee.find_by(:first_name => "Jeffrey").business_title).to eq("Software Development Team Lead")
      expect(Employee.find_by(:first_name => "Jeffrey").employee_type).to eq("Regular")
      expect(Employee.find_by(:first_name => "Jeffrey").location.kind).to eq("Office")
      expect(Employee.find_by(:first_name => "Jeffrey").location.name).to eq("OT Los Angeles")
      expect(Employee.find_by(:first_name => "Jeffrey").manager_id).to eq("12100123")
      expect(Employee.find_by(:first_name => "Jeffrey").department.name).to eq("OT Business Optimization")
      expect(Employee.find_by(:first_name => "Jeffrey").office_phone).to eq("(213) 555-4321")
      expect(Employee.find_by(:first_name => "Jeffrey").image_code).to be_nil
      expect(Employee.find_by(:first_name => "Jeffrey").home_address_1).to be_nil
      expect(Employee.find_by(:first_name => "Jeffrey").home_address_2).to be_nil
      expect(Employee.find_by(:first_name => "Jeffrey").home_city).to be_nil
      expect(Employee.find_by(:first_name => "Jeffrey").home_state).to be_nil
      expect(Employee.find_by(:first_name => "Jeffrey").home_zip).to be_nil
      expect(Employee.find_by(:first_name => "Jeffrey").ad_updated_at).to be_nil
    end

    it "should call EmployeeWorker" do
      expect(EmployeeWorker).to receive(:perform_async).exactly(3).times

      xml.parse_to_db
    end

    it "should have a contract end date for a contingent worker" do
      existing_employee_1 = FactoryGirl.create(:employee, :employee_id => "12100401")
      existing_employee_2 = FactoryGirl.create(:employee, :employee_id => "12101234")

      expect{
        xml.parse_to_db
      }.to change{Employee.count}.from(2).to(3)
      expect(Employee.find_by(:first_name => "Walter").first_name).to eq("Walter")
      expect(Employee.find_by(:first_name => "Walter").last_name).to eq("Sobchak")
      expect(Employee.find_by(:first_name => "Walter").workday_username).to eq("walters")
      expect(Employee.find_by(:first_name => "Walter").employee_id).to eq("109640")
      expect(Employee.find_by(:first_name => "Walter").location.country).to eq("GB")
      expect(Employee.find_by(:first_name => "Walter").hire_date).to eq(DateTime.new(2014,5,2))
      expect(Employee.find_by(:first_name => "Walter").job_family).to eq("OT Contingent Workers")
      expect(Employee.find_by(:first_name => "Walter").job_family_id).to eq("OT_Contingent_Workers")
      expect(Employee.find_by(:first_name => "Walter").job_profile_id).to eq("50100310")
      expect(Employee.find_by(:first_name => "Walter").job_profile).to eq("OT Contingent Worker")
      expect(Employee.find_by(:first_name => "Walter").business_title).to eq("OT Contingent Position - Product Management")
      expect(Employee.find_by(:first_name => "Walter").employee_type).to eq("Vendor")
      expect(Employee.find_by(:first_name => "Walter").location.kind).to eq("Office")
      expect(Employee.find_by(:first_name => "Walter").location.name).to eq("OT London")
      expect(Employee.find_by(:first_name => "Walter").manager_id).to eq("12101502")
      expect(Employee.find_by(:first_name => "Walter").department.name).to eq("OT General Product Management")
      expect(Employee.find_by(:first_name => "Walter").office_phone).to eq("(213) 555-9876")
      expect(Employee.find_by(:first_name => "Walter").image_code).to be_nil
      expect(Employee.find_by(:first_name => "Walter").home_address_1).to be_nil
      expect(Employee.find_by(:first_name => "Walter").home_address_2).to be_nil
      expect(Employee.find_by(:first_name => "Walter").home_city).to be_nil
      expect(Employee.find_by(:first_name => "Walter").home_state).to be_nil
      expect(Employee.find_by(:first_name => "Walter").home_zip).to be_nil
      expect(Employee.find_by(:first_name => "Walter").ad_updated_at).to be_nil
      expect(Employee.find_by(:first_name => "Walter").contract_end_date).to eq(DateTime.new(2016,6,30))
      expect(Employee.find_by(:first_name => "Walter").contingent_worker_type).to eq("Vendor")
      expect(Employee.find_by(:first_name => "Walter").ad_updated_at).to be_nil
    end

    it "should have a home address for a remote worker" do
      existing_employee_1 = FactoryGirl.create(:employee, :employee_id => "12100401")
      existing_employee_2 = FactoryGirl.create(:employee, :employee_id => "109640")

      expect{
        xml.parse_to_db
      }.to change{Employee.count}.from(2).to(3)
      expect(Employee.find_by(:first_name => "Maude").home_address_1).to eq("123 East Side, #2310")
      expect(Employee.find_by(:first_name => "Maude").home_address_2).to be_nil
      expect(Employee.find_by(:first_name => "Maude").home_city).to eq("Chicago")
      expect(Employee.find_by(:first_name => "Maude").home_state).to eq("Illinois")
      expect(Employee.find_by(:first_name => "Maude").home_zip).to eq("60611")
      expect(Employee.find_by(:first_name => "Maude").ad_updated_at).to be_nil
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
      :employee_id => "109843",
      :hire_date => DateTime.new(2016, 4, 7),
      :termination_date => nil,
      :business_title => "OT Fraud Analyst",
      :manager_id => "12101034")
    }
    let!(:returning_employee) { FactoryGirl.create(:employee,
      :employee_id => "12100321",
      :hire_date => DateTime.new(2005, 2, 1),
      :business_title => "Sr. Software Development Team Lead",
      :manager_id => "12101034")
    }
    let!(:previous_leave_emp) { FactoryGirl.create(:employee,
      :employee_id => "1234567",
      :business_title => "Rich Guy",
      :manager_id => "12101034",
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

    it "should send a Security Access Mailer for a business_title change" do
      manager = FactoryGirl.create(:employee, :employee_id => "12100123")
      expect(EmployeeWorker).to receive(:perform_async).with("job_change", employee.id)

      xml.parse_to_db
    end

    it "should send an Onboarding email for a rehire" do
      employee.hire_date = employee.hire_date - 5.years
      employee.termination_date = employee.hire_date - 3.years
      employee.save!

      manager = FactoryGirl.create(:employee, :employee_id => "12100123")

      expect(EmployeeWorker).to receive(:perform_async).with("onboard", employee.id)

      xml.parse_to_db
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
