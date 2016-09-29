class SummaryReportMailerPreview < ActionMailer::Preview
  def onboard
    SummaryReportMailer.onboard_report
  end

  def offboard
    SummaryReportMailer.offboard_report
  end
end
