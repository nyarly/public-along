require "rails_helper"

RSpec.describe TechTableMailer, type: :mailer do
  context "alert_email" do
    let!(:email) { TechTableMailer.alert_email("This message that gets passed in").deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["no-reply@opentable.com"])
      expect(email.to).to include("techtable@opentable.com")
      expect(email.subject).to eq("ALERT: Mezzo Error")
      expect(email.parts.first.body.raw_source).to include("This message that gets passed in")
    end
  end

  context "permission" do
    let(:user) { FactoryGirl.create(:user)}
    let(:emp) { FactoryGirl.create(:employee, worker_type_id: wt.id)}
    let(:wt) { FactoryGirl.create(:worker_type, kind: "Regular")}
    let(:et) { FactoryGirl.create(:emp_transaction, user_id: user.id, kind: "Onboarding")}
    let!(:email) { TechTableMailer.permissions(et, emp).deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["no-reply@opentable.com"])
      expect(email.to).to include("techtable@opentable.com")
      expect(email.subject).to eq("IMMEDIATE ACTION REQUIRED: #{et.kind} request for #{emp.first_name} #{emp.last_name}")
      expect(email.parts.first.body.raw_source).to include("Onboarding")
    end
  end

  context "offboard notice" do
    let(:emp) { FactoryGirl.create(:employee, termination_date: 2.weeks.from_now, manager_id: "123456")}
    let!(:mgr) { FactoryGirl.create(:employee, employee_id: "123456")}
    let!(:email) { TechTableMailer.offboard_notice(emp).deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["no-reply@opentable.com"])
      expect(email.to).to include("techtable@opentable.com")
      expect(email.subject).to eq("Mezzo Offboarding notice for #{emp.first_name} #{emp.last_name}")
      expect(email.parts.first.body.raw_source).to include("Upcoming Offboard Notice")
    end
  end

  context "offboard status" do
    let!(:employee) { FactoryGirl.create(:employee, termination_date: Date.new(2017, 6, 1), manager_id: "123456") }
    let!(:emp_transaction) {FactoryGirl.create(:emp_transaction) }
    let!(:offboarding_info) { FactoryGirl.create(:offboarding_info, emp_transaction_id: emp_transaction.id, employee_id: employee.id) }
    let!(:email) { TechTableMailer.offboard_status(emp_transaction, employee).deliver_now }

    Timecop.freeze(Time.new(2017, 6, 01, 15, 30, 0, "+00:00"))

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["no-reply@opentable.com"])
      expect(email.to).to include("techtable@opentable.com")
      expect(email.subject).to eq("Mezzo Automated Offboarding Status for #{employee.first_name} #{employee.last_name}")
      expect(email.parts.first.body.raw_source).to include("Mezzo Automatic Offboarding Status")
    end
  end
end
