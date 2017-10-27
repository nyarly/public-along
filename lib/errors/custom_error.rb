module Errors
  class CustomError
    attr_reader :status, :error, :message

    def initialize(status=nil, error=nil, message=nil)
      @error = error
      @status = status
      @message = message
    end
  end
end
