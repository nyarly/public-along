class PeopleAndCultureMailer < ApplicationMailer
  default to: [Rails.application.secrets.pc_email]

  def code_list_email(items)
    @items = items
    mail(subject: "Mezzo Request for Code List Updates")
  end
end
