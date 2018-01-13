class Sessionable
  include Tokenable
  attr_accessor :token

  def initialize(session)
    @session = session
    @token = token
  end

  def change_token
    @session[:submission_token] = token
  end

  private

  def token
    @token ||= generate_token
  end
end
