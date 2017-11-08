module Errors
  class Handler
    def initialize(mailer, subject, message, data)
      @mailer = mailer
      @subject = subject
      @message = message
      @data = data
    end

    def process!
      log_issue
      send_message
    end

    def log_issue
      Rails.logger.info "WARNING: Mezzo Processing Issue"
      Rails.logger.info @subject
      Rails.logger.info @message
      Rails.logger.info @data if @data.present?
    end

    def send_message
      @mailer.alert(@subject, @message, @data).deliver_now
    end
  end
end
