class SummaryReportMailer < ApplicationMailer
  default from: 'no-reply@opentable.com'

  def report(kind)
    @kind = kind
    csv = SummaryReportHelper::Csv.new

    if kind == "Onboard"
      attachments.inline["onboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.onboarding_data
      mail(to: "onboardapproved@opentable.com", subject: "Onboard Summary Report")
    elsif kind == "Offboard"
      attachments.inline["offboarding_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.offboarding_data
      mail(to: "offboardapproved@opentable.com", subject: "Offboard Summary Report")
    end
  end
end
