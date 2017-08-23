require "rails_helper"

RSpec.describe ManagerMailer, type: :mailer do
  let!(:manager) { FactoryGirl.create(:regular_employee,
    email: "manager@opentable.com") }
  let!(:employee) { FactoryGirl.create(:employee) }
  let!(:profile) { FactoryGirl.create(:profile,
    employee: employee,
    adp_employee_id: "654321",
    manager_id: manager.employee_id) }

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
      expect(email.text_part.body).to include("You must complete this form by #{employee.onboarding_due_date}")
      expect(email.html_part.body).to include("You must complete this form by #{employee.onboarding_due_date}")
    end
  end

  context "Onboarding Rehire/Job Change" do
    let(:rehire_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_rehire_event.json") }
    let!(:event) { AdpEvent.new(status: "New",
      json: rehire_json)}
    let!(:profiler) { EmployeeProfile.new }

    it "should queue to send" do
      employee = profiler.build_employee(event)
      manager = employee.manager
      email = ManagerMailer.permissions("Onboarding", manager, employee, event: event)
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      employee = profiler.build_employee(event)
      manager = employee.manager
      email = ManagerMailer.permissions("Onboarding", manager, employee, event: event)
      expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
      expect(email.to).to eq(["manager@opentable.com"])
      expect(email.subject).to eq("IMMEDIATE ACTION REQUIRED: Employee Event Form for Bob Fakename")
      expect(email.text_part.body).to include("Follow the link below to complete the employee event form")
      expect(email.html_part.body).to include("Follow the link below to complete the employee event form")
      expect(email.text_part.body).to include("You must complete this form by September 1, 2010")
      expect(email.html_part.body).to include("You must complete this form by September 1, 2010")
    end
  end
end
