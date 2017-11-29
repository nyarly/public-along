require 'rails_helper'
require 'rake'

describe "report rake tasks", type: :tasks do
  let(:mailer) { double(SummaryReportMailer) }

  before :each do
    Rake.application = Rake::Application.new
    Rake.application.rake_require "lib/tasks/report", [Rails.root.to_s], ''
    Rake::Task.define_task :environment
  end

  context "employee change summaries" do
    it "should send daily onboarding report" do
      expect(SummaryReportMailer).to receive(:daily_onboard_report).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      Rake::Task["report:daily_onboards"].invoke
    end

    it "should send weekly onboarding report" do
      expect(SummaryReportMailer).to receive(:weekly_onboard_report).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      Rake::Task["report:weekly_onboards"].invoke
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

  context "audit report tasks", type: :tasks do
    it "should send a termination audit report" do
      expect(SummaryReportMailer).to receive(:termination_audit_report).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      Rake::Task["report:missed_terminations"].execute
    end

    it "should send a deactivation audit report", type: :tasks do
      expect(SummaryReportMailer).to receive(:deactivation_audit_report).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      Rake::Task["report:missed_deactivations"].execute
    end
  end
end
