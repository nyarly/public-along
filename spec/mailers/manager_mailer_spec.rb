require "rails_helper"

RSpec.describe ManagerMailer, type: :mailer do
  let!(:ceo)         { FactoryGirl.create(:active_employee, email: "ceo@opentable.com") }
  let!(:ceo_profile) { FactoryGirl.create(:active_profile,
                       adp_employee_id: "111111",
                       employee: ceo) }
  let!(:manager)     { FactoryGirl.create(:active_employee,
                       email: "manager@opentable.com",
                       manager: ceo) }
  let!(:man_profile) { FactoryGirl.create(:active_profile,
                       employee: manager,
                       adp_employee_id: "654321") }
  let!(:employee)    { FactoryGirl.create(:active_employee, manager: manager) }
  let!(:emp_profile) { FactoryGirl.create(:active_profile,
                       employee: employee,
                       adp_employee_id: "123456",
                       manager_adp_employee_id: "654321") }
  let!(:worker_type) { FactoryGirl.create(:worker_type, code: "FTR") }
  let(:rehire_json)  { File.read(Rails.root.to_s+"/spec/fixtures/adp_rehire_event.json") }
  let!(:event)       { AdpEvent.new(status: "New", json: rehire_json) }
  let!(:profiler)    { EmployeeProfile.new }

  context "Onboarding reminder" do
    let!(:reminder_email)   { ManagerMailer.reminder(manager, employee, "reminder").deliver_now }
    let!(:escalation_email) { ManagerMailer.reminder(ceo, employee, "escalation").deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "reminder email should have the right content" do
      expect(reminder_email.from).to eq(["mezzo-no-reply@opentable.com"])
      expect(reminder_email.to).to eq(["manager@opentable.com"])
      expect(reminder_email.subject).to eq("Urgent: Mezzo Onboarding Form Due Tomorrow for #{employee.first_name} #{employee.last_name}")
      expect(reminder_email.text_part.body).to include("Follow the link below to complete the employee event form")
      expect(reminder_email.html_part.body).to include("Follow the link below to complete the employee event form")
      expect(reminder_email.text_part.body).to include("user_emp_id=654321")
      expect(reminder_email.html_part.body).to include("user_emp_id=654321")
    end

    it "escalation email should have the right content" do
      expect(escalation_email.from).to eq(["mezzo-no-reply@opentable.com"])
      expect(escalation_email.to).to eq(["ceo@opentable.com"])
      expect(escalation_email.subject).to eq("Urgent: Mezzo Onboarding Form Due Tomorrow for #{employee.first_name} #{employee.last_name}")
      expect(escalation_email.text_part.body).to include("Follow the link below to complete the employee event form")
      expect(escalation_email.html_part.body).to include("Follow the link below to complete the employee event form")
      expect(escalation_email.text_part.body).to include("user_emp_id=111111")
      expect(escalation_email.html_part.body).to include("user_emp_id=111111")
    end
  end

  context "Security Access" do
    let!(:email) { ManagerMailer.permissions("Security Access", manager, employee).deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
      expect(email.to).to eq(["manager@opentable.com"])
      expect(email.subject).to eq("IMMEDIATE ACTION REQUIRED: Employee Event Form for #{employee.first_name} #{employee.last_name}")
      expect(email.text_part.body).to include("Follow the link below to complete the employee event form")
      expect(email.html_part.body).to include("Follow the link below to complete the employee event form")
    end
  end

  context "Equipment" do
    let!(:email) { ManagerMailer.permissions("Equipment", manager, employee).deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
      expect(email.to).to eq(["manager@opentable.com"])
      expect(email.subject).to eq("IMMEDIATE ACTION REQUIRED: Employee Event Form for #{employee.first_name} #{employee.last_name}")
      expect(email.text_part.body).to include("Follow the link below to complete the employee event form")
      expect(email.html_part.body).to include("Follow the link below to complete the employee event form")
    end
  end

  context "Onboarding" do
    let!(:email) { ManagerMailer.permissions("Onboarding", manager, employee).deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
      expect(email.to).to eq(["manager@opentable.com"])
      expect(email.subject).to eq("IMMEDIATE ACTION REQUIRED: Employee Event Form for #{employee.first_name} #{employee.last_name}")
      expect(email.text_part.body).to include("Follow the link below to complete the employee event form")
      expect(email.html_part.body).to include("Follow the link below to complete the employee event form")
      expect(email.text_part.body).to include("You must complete this form by #{employee.onboarding_due_date.try(:strftime, "%b %e, %Y")}")
      expect(email.html_part.body).to include("You must complete this form by #{employee.onboarding_due_date.try(:strftime, "%b %e, %Y")}")
    end
  end

  context "Onboarding Rehire/Job Change" do
    it "should queue to send" do
      employee = profiler.build_employee(event)
      manager = employee.manager
      email = ManagerMailer.permissions("Onboarding", manager, employee, event: event).deliver_now
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      employee = profiler.build_employee(event)
      manager = employee.manager
      email = ManagerMailer.permissions("Onboarding", manager, employee, event: event).deliver_now
      expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
      expect(email.to).to eq(["manager@opentable.com"])
      expect(email.subject).to eq("IMMEDIATE ACTION REQUIRED: Employee Event Form for Bob Fakename")
      expect(email.text_part.body).to include("Follow the link below to complete the employee event form")
      expect(email.html_part.body).to include("Follow the link below to complete the employee event form")
      expect(email.text_part.body).to include("You must complete this form by Aug 24, 2018")
      expect(email.html_part.body).to include("You must complete this form by Aug 24, 2018")
    end
  end
end
