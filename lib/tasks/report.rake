namespace :report do
  desc "send onboarding summary reports"
  task :onboards => :environment do
    SummaryReportMailer.onboard_report.deliver_now
  end

  desc "send job change summary reports"
  task :job_changes => :environment do
    SummaryReportMailer.job_change_report.deliver_now if EmpDelta.report_group.count > 0
  end

  desc "send offboarding summary reports"
  task :offboards => :environment do
    SummaryReportMailer.offboard_report.deliver_now
  end

  desc "audit terminations and send report"
  task :missed_terminations => :environment do
    SummaryReportMailer.termination_audit_report.deliver_now
  end

  desc "audit deactivations and send report"
  task :missed_deactivations => :environment do
    SummaryReportMailer.deactivation_audit_report.deliver_now
  end
end
