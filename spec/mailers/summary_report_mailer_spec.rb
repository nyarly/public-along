require "rails_helper"

RSpec.describe SummaryReportMailer, type: :mailer do
  let(:helper) { double(SummaryReportHelper) }

  context "Onboarding" do
    let(:email) { SummaryReportMailer.report("Onboard").deliver_now }

    it "should have the correct content and queue to send" do
      expect(SummaryReportHelper::Csv).to receive(:new).and_return(helper)
      expect(helper).to receive(:onboarding_data)
      expect(email.attachments.count).to eq(1)
      expect(email.attachments[0].content_type).to have_content("text/comma-separated-values")
      expect(email.attachments[0].filename).to eq("onboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv")
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end
  end

  context "Offboarding" do
    let(:email) { SummaryReportMailer.report("Offboard").deliver_now }

    it "should have the correct content and queue to send" do
      expect(SummaryReportHelper::Csv).to receive(:new).and_return(helper)
      expect(helper).to receive(:offboarding_data)
      expect(email.attachments.count).to eq(1)
      expect(email.attachments[0].content_type).to have_content('text/comma-separated-values')
      expect(email.attachments[0].filename).to eq("offboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv")
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end
  end
end
