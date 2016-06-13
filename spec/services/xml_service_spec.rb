require 'rails_helper'

describe XmlService, type: :service do
  let(:xml) { XmlService.new(file) }

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
      expect(Employee.last.country).to eq("US")
      expect(Employee.last.hire_date).to eq(DateTime.new(2016,4,25))
      expect(Employee.last.job_family).to eq("OT Internal Systems")
      expect(Employee.last.job_family_id).to eq("OT_Internal_Systems")
      expect(Employee.last.job_profile_id).to eq("50100486")
      expect(Employee.last.job_profile).to eq("OT Internal Systems")
      expect(Employee.last.business_title).to eq("Software Development Team Lead")
      expect(Employee.last.employee_type).to eq("Regular")
      expect(Employee.last.location_type).to eq("Office")
      expect(Employee.last.location).to eq("OT Los Angeles")
      expect(Employee.last.manager_id).to eq("12100123")
      expect(Employee.last.cost_center).to eq("OT Business Optimization")
      expect(Employee.last.cost_center_id).to eq("000044")
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
      expect(Employee.last.country).to eq("GB")
      expect(Employee.last.hire_date).to eq(DateTime.new(2014,5,2))
      expect(Employee.last.job_family).to eq("OT Contingent Workers")
      expect(Employee.last.job_family_id).to eq("OT_Contingent_Workers")
      expect(Employee.last.job_profile_id).to eq("50100310")
      expect(Employee.last.job_profile).to eq("OT Contingent Worker")
      expect(Employee.last.business_title).to eq("OT Contingent Position - Product Management")
      expect(Employee.last.employee_type).to eq("Vendor")
      expect(Employee.last.location_type).to eq("Office")
      expect(Employee.last.location).to eq("OT London")
      expect(Employee.last.manager_id).to eq("12101502")
      expect(Employee.last.cost_center).to eq("OT General Product Management")
      expect(Employee.last.cost_center_id).to eq("WP8OT_London000060")
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
      :cost_center => "OT Business Optimization",
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

end
