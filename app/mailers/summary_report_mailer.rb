class SummaryReportMailer < ApplicationMailer
  default from: 'no-reply@opentable.com'

  def onboard_report
    csv = SummaryReportHelper::Csv.new

    attachments.inline["onboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.onboarding_data
    mail(to: Rails.application.secrets.onboard_email, subject: "Onboard Summary Report")
  end

  def offboard_report
    offboard = (Rails.env.production? ? "offboardapproved@opentable.com" : "pho@opentable.com")
    csv = SummaryReportHelper::Csv.new

    attachments.inline["offboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.offboarding_data
    mail(to: Rails.application.secrets.offboard_email, subject: "Offboard Summary Report")
  end
end
