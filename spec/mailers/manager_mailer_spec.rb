require "rails_helper"

RSpec.describe ManagerMailer, type: :mailer do
  context "permissions" do
    let(:manager) { FactoryGirl.create(:employee, email: "manager@opentable.com") }
    let(:employee) { FactoryGirl.create(:employee, manager_id: manager.employee_id) }
    let!(:email) { ManagerMailer.permissions(manager, employee).deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["no-reply@opentable.com"])
      expect(email.to).to eq(["manager@opentable.com"])
      expect(email.subject).to eq("IMMEDIATE ACTION REQUIRED: Onboarding forms for new hire - #{employee.first_name} #{employee.last_name}")
      expect(email.body.to_s).to include("You must complete the onboarding forms by")
    end
  end
end
