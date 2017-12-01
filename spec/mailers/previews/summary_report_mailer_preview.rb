class SummaryReportMailerPreview < ActionMailer::Preview
  def onboard
    SummaryReportMailer.onboard_report
  end

  def offboard
    SummaryReportMailer.offboard_report
  end

  def job_changes
    SummaryReportMailer.job_change_report
  end
end
