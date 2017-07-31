class SummaryReportMailer < ApplicationMailer
  def onboard_report
    csv = SummaryReportHelper::Csv.new

    attachments.inline["onboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.onboarding_data
    attachments.inline['pandc.png'] = File.read(Rails.root.join('app/assets/images/pandc.png'))
    mail(to: Rails.application.secrets.onoffboard_email, subject: "Onboard Summary Report")
  end

  def offboard_report
    csv = SummaryReportHelper::Csv.new

    attachments.inline["offboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.offboarding_data
    attachments.inline['pandc.png'] = File.read(Rails.root.join('app/assets/images/pandc.png'))
    mail(to: Rails.application.secrets.onoffboard_email, subject: "Offboard Summary Report")
  end

  def job_change_report
    csv = SummaryReportHelper::Csv.new

    attachments.inline["job_change_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.job_change_data
    attachments.inline['pandc.png'] = File.read(Rails.root.join('app/assets/images/pandc.png'))
    mail(to: Rails.application.secrets.onoffboard_email, subject: "Job Change Summary Report")
  end

  def termination_audit_report
    audit = AuditService.new
    missed_terminations = audit.missed_terminations

    attachments.inline["audit_summary_#{DateTime.now}.csv"] = audit.generate_csv(missed_terminations)
    mail(to: "pburke@opentable.com", subject: "Mezzo Missed Termination Audit")
  end

  def deactivation_audit_report
    audit = AuditService.new
    missed_deactivations = audit.ad_deactivation
    attachments.inline["audit_summary_#{DateTime.now}.csv"] = audit.generate_csv(missed_deactivations)
    mail(to: Rails.application.secrets.tt_email, subject: "Mezzo Missed Deactivation Audit")
  end
end
