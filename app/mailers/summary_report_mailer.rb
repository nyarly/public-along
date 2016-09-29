class SummaryReportMailer < ApplicationMailer
  default from: 'no-reply@opentable.com'

  def onboard_report
    csv = SummaryReportHelper::Csv.new

    attachments.inline["onboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.onboarding_data
    mail(to: "onboardapproved@opentable.com", subject: "Onboard Summary Report")
  end

  def offboard_report
    csv = SummaryReportHelper::Csv.new

    attachments.inline["offboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.offboarding_data
    mail(to: "offboardapproved@opentable.com", subject: "Offboard Summary Report")
  end
end
