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

  def terminate_contract(worker)
    @worker = worker
    subject = "Please Terminate Worker #{@worker.cn}"
    mail(subject: subject)
  end

  def upcoming_contract_end(worker)
    @worker = worker
    subject = "Contract for #{@worker.cn} will expire in 3 weeks"
    mail(subject: subject)
  end
end
