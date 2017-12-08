class SummaryReportMailer < ApplicationMailer
  def daily_onboard_report
    report = Report::Onboard::Daily.new
    file_name = "daily_#{DateTime.now.strftime('%Y%m%d')}.xls"
    @onboards = OnboardQuery.new.added_and_updated_onboards

    attachments.inline[file_name] = File.read(Rails.root.join('tmp/reports/onboard/' + file_name))
    attachments.inline['pandc.png'] = File.read(Rails.root.join('app/assets/images/pandc.png'))
    mail(to: Rails.application.secrets.onoffboard_email, subject: "Daily Onboard Summary Report")
  end

  def weekly_onboard_report
    @onboards = OnboardQuery.new.onboarded_this_week
    @onboard_count = @onboards.size

    attachments.inline['pandc.png'] = File.read(Rails.root.join('app/assets/images/pandc.png'))
    mail(to: Rails.application.secrets.onoffboard_email, subject: "Weekly Onboard Summary Report")
  end

  def offboard_report
    csv = SummaryReportHelper::Csv.new
    @offboards = OnboardQuery.new.added_and_updated_offboards

    attachments.inline["offboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.offboarding_data
    attachments.inline['pandc.png'] = File.read(Rails.root.join('app/assets/images/pandc.png'))
    mail(to: Rails.application.secrets.onoffboard_email, subject: "Offboard Summary Report")
  end

  def job_change_report
    csv = SummaryReportHelper::Csv.new

    @job_changes = EmpDelta.report_group
    attachments.inline["job_change_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.job_change_data
    attachments.inline['pandc.png'] = File.read(Rails.root.join('app/assets/images/pandc.png'))
    mail(to: Rails.application.secrets.onoffboard_email, subject: "Job Change Summary Report")
  end

  def termination_audit_report
    audit = AuditService.new
    missed_terminations = audit.missed_terminations
    csv = audit.generate_csv(missed_terminations)
    attachments.inline["term_audit_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv
    mail(to: Rails.application.secrets.tt_email, subject: "Mezzo Missed Termination Audit")
  end

  def deactivation_audit_report
    audit = AuditService.new
    missed_deactivations = audit.ad_deactivation
    csv = audit.generate_csv(missed_deactivations)
    attachments.inline["deactiv_audit_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv
    mail(to: Rails.application.secrets.tt_email, subject: "Mezzo Missed Deactivation Audit")
  end
end
