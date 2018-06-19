module Tokenable
  def generate_token
    SecureRandom.urlsafe_base64(nil, false)
  end
end
