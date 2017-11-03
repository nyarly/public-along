class PeopleAndCultureMailer < ApplicationMailer
  default to: ["pcemail@opentable.com"]

  def alert(subject, message, data)
    @subject = subject
    @message = message
    @data = data
    mail(subject: @subject)
  end

  def code_list_alert(items)
    @items = items
    mail(subject: "Mezzo Request for Code List Updates")
  end
end
