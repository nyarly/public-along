require "rails_helper"

RSpec.describe PeopleAndCultureMailer, type: :mailer do
  context "code list alert email" do
    let(:new_location) { FactoryGirl.create(:location,
      code: "123ABV",
      name: "Paris",
      status: "Active")}
    let!(:email) { PeopleAndCultureMailer.code_list_alert([new_location]).deliver_now}

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
      expect(email.to).to include("pcemail@opentable.com")
      expect(email.subject).to eq("Mezzo Request for Code List Updates")
      expect(email.parts.first.body.raw_source).to include("The following items must be updated in Mezzo:")
      expect(email.parts.first.body.raw_source).to include("New Location:")
    end
  end
end
