require 'rails_helper'
require 'rake'

describe "report rake tasks", type: :tasks do
  context "employee change summaries" do
    let(:mailer) { double(SummaryReportMailer) }

    before :each do
      Rake.application = Rake::Application.new
      Rake.application.rake_require "lib/tasks/report", [Rails.root.to_s], ''
      Rake::Task.define_task :environment
    end

    it "should send onboarding report" do
      expect(SummaryReportMailer).to receive(:onboard_report).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      Rake::Task["report:onboards"].invoke
    end

    it "should send offboarding report" do
      expect(SummaryReportMailer).to receive(:offboard_report).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      Rake::Task["report:offboards"].invoke
    end

    it "should send job change report if EmpDelta.report_group count > 0" do
      expect(EmpDelta).to receive_message_chain(:report_group, :count).and_return(4)
      expect(SummaryReportMailer).to receive(:job_change_report).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      Rake::Task["report:job_changes"].invoke
    end

    it "should send job change report if EmpDelta.report_group count = 0" do
      expect(EmpDelta).to receive_message_chain(:report_group, :count).and_return(0)
      expect(SummaryReportMailer).to_not receive(:job_change_report)
      Rake::Task["report:job_changes"].execute
    end
  end
end
