require "rails_helper"

RSpec.describe TechTableMailer, type: :mailer do
  context "alert_email" do
    let!(:email) { TechTableMailer.alert_email("This message that gets passed in").deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["no-reply@opentable.com"])
      expect(email.to).to eq(["techtable@opentable.com"])
      expect(email.subject).to eq("ALERT: Workday Integration Error")
      expect(email.body.to_s).to eq("<html>\n  <body>\n    <h1>ALERT: Workday Integration</h1>\n\n<pre>This message that gets passed in</pre>\n\n  </body>\n</html>\n")
    end
  end
end
