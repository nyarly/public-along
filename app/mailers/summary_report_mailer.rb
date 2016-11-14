class SummaryReportMailer < ApplicationMailer
  def onboard_report
    csv = SummaryReportHelper::Csv.new

    attachments.inline["onboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.onboarding_data
    attachments.inline['pandc.png'] = File.read(Rails.root.join('app/assets/images/pandc.png'))
    mail(to: Rails.application.secrets.onboard_email, subject: "Onboard Summary Report")
  end

  def offboard_report
    csv = SummaryReportHelper::Csv.new

    attachments.inline["offboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.offboarding_data
    attachments.inline['pandc.png'] = File.read(Rails.root.join('app/assets/images/pandc.png'))
    mail(to: Rails.application.secrets.offboard_email, subject: "Offboard Summary Report")
  end

  def job_change_report
    csv = SummaryReportHelper::Csv.new

    attachments.inline["job_change_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.job_change_data
    attachments.inline['pandc.png'] = File.read(Rails.root.join('app/assets/images/pandc.png'))
    mail(to: Rails.application.secrets.onboard_email, subject: "Job Change Summary Report")
  end
end
