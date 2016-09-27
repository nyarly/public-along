class SummaryReportMailerPreview < ActionMailer::Preview
  def csv
    SummaryReportMailer.report
  end
end
