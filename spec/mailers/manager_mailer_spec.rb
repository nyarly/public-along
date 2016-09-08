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
      expect(email.from).to eq(["no-reply@opentable.com"])
      expect(email.to).to eq(["manager@opentable.com"])
      expect(email.subject).to eq("IMMEDIATE ACTION REQUIRED: Security Access forms for #{employee.first_name} #{employee.last_name}")
      expect(email.body.to_s).to include("Please follow the link below to complete the security access form")
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
      expect(email.from).to eq(["no-reply@opentable.com"])
      expect(email.to).to eq(["manager@opentable.com"])
      expect(email.subject).to eq("IMMEDIATE ACTION REQUIRED: Equipment forms for #{employee.first_name} #{employee.last_name}")
      expect(email.body.to_s).to include("Please follow the link below to complete the equipment form")
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
      expect(email.from).to eq(["no-reply@opentable.com"])
      expect(email.to).to eq(["manager@opentable.com"])
      expect(email.subject).to eq("IMMEDIATE ACTION REQUIRED: Onboarding forms for #{employee.first_name} #{employee.last_name}")
      expect(email.body.to_s).to include("Please follow the link below to complete the onboarding form")
      expect(email.body.to_s).to include("You must complete the onboarding forms by #{employee.onboarding_due_date}")
    end
  end
end
