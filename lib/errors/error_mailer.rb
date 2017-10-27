module Errors
  class ErrorMailer
    def initialize(mailer, subject, employee, message)
      @mailer = mailer
      @subject = subject
      @employee = employee
      @message = message
    end

    def send_message
      @mailer.alert(@subject, @message)
    end
  end
end
