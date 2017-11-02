module Errors
  class ErrorMailer
    def initialize(mailer, subject, message, data)
      @mailer = mailer
      @subject = subject
      @message = message
      @data = data
    end

    def send_message
      @mailer.alert(@subject, @message, @data).deliver_now
    end
  end
end
