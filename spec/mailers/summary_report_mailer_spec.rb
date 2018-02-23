require 'rails_helper'

RSpec.describe SummaryReportMailer, type: :mailer do
  let(:helper)  { double(SummaryReportHelper) }
  let(:service) { Report::Onboarding }

  describe '.daily_onboard_report' do
    let(:email) { SummaryReportMailer.daily_onboard_report.deliver_now }

    it 'sends to onoffboardreport mailing list' do
      expect(email.to).to eq(['onoffboardreport@opentable.com'])
    end

    it 'has the right subject' do
      expect(email.subject).to eq('Daily Onboard Summary Report')
    end

    it 'attaches a doc with the right format' do
      expect(email.attachments[0].content_type).to have_content('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    end

    it 'attaches a doc with the right name' do
      expect(email.attachments[0].filename).to eq("daily_#{DateTime.now.strftime('%Y%m%d')}.xlsx")
    end

    it 'adds the email to the queue' do
      SummaryReportMailer.daily_onboard_report.deliver_now
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end
  end

  describe "Weekly Onboarding" do
    let(:email) { SummaryReportMailer.weekly_onboard_report.deliver_now }

    it "should have the correct content and queue to send" do
      expect(email.to).to eq(["onoffboardreport@opentable.com"])
      expect(email.subject).to eq("Weekly Onboard Summary Report")
      expect(email.attachments.count).to eq(1)
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end
  end

  describe "Offboarding" do
    let(:email) { SummaryReportMailer.offboard_report.deliver_now }

    it "should have the correct content and queue to send" do
      expect(SummaryReportHelper::Csv).to receive(:new).and_return(helper)
      expect(helper).to receive(:offboarding_data)
      expect(email.to).to eq(["onoffboardreport@opentable.com"])
      expect(email.subject).to eq("Offboard Summary Report")
      expect(email.attachments.count).to eq(2)
      expect(email.attachments[0].content_type).to have_content('text/comma-separated-values')
      expect(email.attachments[0].filename).to eq("offboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv")
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end
  end

  describe "Job Change" do
    let(:email) { SummaryReportMailer.job_change_report.deliver_now }

    it "should have the correct content and queue to send" do
      expect(SummaryReportHelper::Csv).to receive(:new).and_return(helper)
      expect(helper).to receive(:job_change_data)
      expect(email.to).to eq(["onoffboardreport@opentable.com"])
      expect(email.subject).to eq("Job Change Summary Report")
      expect(email.attachments.count).to eq(2)
      expect(email.attachments[0].content_type).to have_content('text/comma-separated-values')
      expect(email.attachments[0].filename).to eq("job_change_summary_#{DateTime.now.strftime('%Y%m%d')}.csv")
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end
  end
end
