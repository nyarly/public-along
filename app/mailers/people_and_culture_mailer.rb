class PeopleAndCultureMailer < ApplicationMailer
  default to: ["pcemail@opentable.com"]

  def code_list_alert(items)
    @items = items
    mail(subject: "Mezzo Request for Code List Updates")
  end
end
