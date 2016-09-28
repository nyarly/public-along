class SummaryReportMailerPreview < ActionMailer::Preview
  def onboard
    SummaryReportMailer.report("Onboard")
  end

  def offboard
    SummaryReportMailer.report("Offboard")
  end
end
