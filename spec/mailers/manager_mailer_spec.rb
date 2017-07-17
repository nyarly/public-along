require "rails_helper"

RSpec.describe ManagerMailer, type: :mailer do
  context "Security Access" do
    let(:manager) { FactoryGirl.create(:employee, email: "manager@opentable.com") }
    let(:employee) { FactoryGirl.create(:employee, manager_id: manager.employee_id) }
    let!(:email) { ManagerMailer.permissions(manager, employee, "Security Access").deliver_now }

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
    let(:manager) { FactoryGirl.create(:employee, email: "manager@opentable.com") }
    let(:employee) { FactoryGirl.create(:employee, manager_id: manager.employee_id) }
    let!(:email) { ManagerMailer.permissions(manager, employee, "Equipment").deliver_now }

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
    let(:manager) { FactoryGirl.create(:employee, email: "manager@opentable.com") }
    let(:employee) { FactoryGirl.create(:employee, manager_id: manager.employee_id) }
    let!(:email) { ManagerMailer.permissions(manager, employee, "Onboarding").deliver_now }

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
end
