module Tokenable
  attr_accessor :generate_token

  def generate_token
    SecureRandom.urlsafe_base64(nil, false)
  end
end
