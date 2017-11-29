class SummaryReportMailerPreview < ActionMailer::Preview
  def daily_onboard
    SummaryReportMailer.daily_onboard_report
  end

  def weekly_onboard
    SummaryReportMailer.weekly_onboard_report
  end

  def offboard
    SummaryReportMailer.offboard_report
  end
end
