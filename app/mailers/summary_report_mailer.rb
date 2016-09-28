class SummaryReportMailer < ApplicationMailer
  default from: 'no-reply@opentable.com'

  def report(kind)
    @kind = kind
    csv = SummaryReportHelper::Csv.new

    if ["Onboard", "Offboard"].include?(@kind)
      attachments.inline["#{@kind.downcase}ing_summary_#{DateTime.now.strftime('%Y%m%d')}.csv"] = csv.send("#{@kind.downcase}ing_data")
      mail(to: "#{@kind.downcase}approved@opentable.com", subject: "#{@kind} Summary Report")
    end
  end
end
