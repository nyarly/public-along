require "rails_helper"

RSpec.describe SummaryReportMailer, type: :mailer do
  let(:helper) { double(SummaryReportHelper) }

  context "Onboarding" do
    let(:email) { SummaryReportMailer.onboard_report.deliver_now }

    it "should have the correct content and queue to send" do
      expect(SummaryReportHelper::Csv).to receive(:new).and_return(helper)
      expect(helper).to receive(:onboarding_data)
      expect(email.to).to eq(["onboardapproved@opentable.com"])
      expect(email.subject).to eq("Onboard Summary Report")
      expect(email.attachments.count).to eq(2)
      expect(email.attachments[0].content_type).to have_content("text/comma-separated-values")
      expect(email.attachments[0].filename).to eq("onboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv")
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end
  end

  context "Offboarding" do
    let(:email) { SummaryReportMailer.offboard_report.deliver_now }

    it "should have the correct content and queue to send" do
      expect(SummaryReportHelper::Csv).to receive(:new).and_return(helper)
      expect(helper).to receive(:offboarding_data)
      expect(email.to).to eq(["offboardapproved@opentable.com"])
      expect(email.subject).to eq("Offboard Summary Report")
      expect(email.attachments.count).to eq(2)
      expect(email.attachments[0].content_type).to have_content('text/comma-separated-values')
      expect(email.attachments[0].filename).to eq("offboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv")
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end
  end

  context "Job Change" do
    let(:email) { SummaryReportMailer.job_change_report.deliver_now }

    it "should have the correct content and queue to send" do
      expect(SummaryReportHelper::Csv).to receive(:new).and_return(helper)
      expect(helper).to receive(:job_change_data)
      expect(email.to).to eq(["onboardapproved@opentable.com"])
      expect(email.subject).to eq("Job Change Summary Report")
      expect(email.attachments.count).to eq(2)
      expect(email.attachments[0].content_type).to have_content('text/comma-separated-values')
      expect(email.attachments[0].filename).to eq("job_change_summary_#{DateTime.now.strftime('%Y%m%d')}.csv")
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end
  end
end
