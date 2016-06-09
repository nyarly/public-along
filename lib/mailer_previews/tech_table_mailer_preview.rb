class TechTableMailerPreview < ActionMailer::Preview
  def alert_email
    message = "This went wrong. It needs to be fixed manually."
    TechTableMailer.alert_email(message)
  end
end
