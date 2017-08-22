require "rails_helper"

RSpec.describe TechTableMailer, type: :mailer do
  context "alert_email" do
    let!(:email) { TechTableMailer.alert_email("This message that gets passed in").deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
      expect(email.to).to include("techtable@opentable.com")
      expect(email.subject).to eq("ALERT: Mezzo Error")
      expect(email.parts.first.body.raw_source).to include("This message that gets passed in")
    end
  end

  context "permission" do
    let(:user) { FactoryGirl.create(:user)}
    let(:emp) { FactoryGirl.create(:regular_employee)}
    let(:et) { FactoryGirl.create(:emp_transaction,
      user_id: user.id,
      kind: "Security Access")}
    let!(:email) { TechTableMailer.permissions(et, emp).deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
      expect(email.to).to include("techtable@opentable.com")
      expect(email.subject).to eq("#{et.kind} request for #{emp.first_name} #{emp.last_name}")
      expect(email.parts.first.body.raw_source).to include("Security Profile Change Requested")
    end
  end

  context "offboard notice" do
    let(:manager) { FactoryGirl.create(:regular_employee,
      email: "manager@opentable.com") }
    let!(:employee) { FactoryGirl.create(:employee,
      termination_date: 1.week.from_now) }
    let!(:profile) { FactoryGirl.create(:profile,
      employee_id: employee.id,
      manager_id: manager.employee_id) }
    let!(:email) { TechTableMailer.offboard_notice(employee).deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
      expect(email.to).to include("techtable@opentable.com")
      expect(email.subject).to eq("Mezzo Offboarding notice for #{employee.first_name} #{employee.last_name}")
      expect(email.parts.first.body.raw_source).to include("Upcoming Offboard Notice")
    end
  end

  context "offboard status" do
    results = {}
    let(:manager) { FactoryGirl.create(:regular_employee,
      email: "manager@opentable.com") }
    let(:employee) { FactoryGirl.create(:employee,
      termination_date: 2.days.from_now) }
    let!(:profile) { FactoryGirl.create(:profile,
      employee: employee,
      manager_id: manager.employee_id) }
    let!(:email) { TechTableMailer.offboard_status(employee, results).deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
      expect(email.to).to include("ComputerClub@opentable.com")
      expect(email.subject).to eq("Mezzo Automated Offboarding Status for #{employee.first_name} #{employee.last_name}")
      expect(email.parts.first.body.raw_source).to include("Mezzo Automatic Offboarding Status")
    end
  end

  context "offboard instructions" do
    let!(:user) { FactoryGirl.create(:user)}
    let(:manager) { FactoryGirl.create(:regular_employee,
      email: "manager@opentable.com") }
    let!(:employee) { FactoryGirl.create(:employee,
      termination_date: 2.days.from_now) }
    let!(:profile) { FactoryGirl.create(:profile,
      employee: employee,
      manager_id: manager.employee_id) }
    let!(:forwarding) { FactoryGirl.create(:employee) }
    let!(:emp_transaction) { FactoryGirl.create(:offboarding_emp_transaction,
      user_id: user.id,
      employee_id: employee.id) }
    let!(:offboarding_info) { FactoryGirl.create(:offboarding_info,
      emp_transaction_id: emp_transaction.id,
      forward_email_id: forwarding.id,
      reassign_salesforce_id: forwarding.id,
      transfer_google_docs_id: forwarding.id) }
    let!(:email) { TechTableMailer.offboard_instructions(employee).deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
      expect(email.to).to include("techtable@opentable.com")
      expect(email.subject).to eq("Mezzo Offboard Instructions for #{employee.first_name} #{employee.last_name}")
      expect(email.parts.first.body.raw_source).to include("Offboarding Worker Request")
    end
  end

  context "onboard instructions" do
    let!(:user) { FactoryGirl.create(:user)}
    let(:manager) { FactoryGirl.create(:regular_employee,
      email: "manager@opentable.com") }
    let!(:employee) { FactoryGirl.create(:employee,
      hire_date: 2.days.from_now) }
    let!(:profile) { FactoryGirl.create(:profile,
      employee: employee,
      manager_id: manager.employee_id) }
    let!(:forwarding) { FactoryGirl.create(:employee) }
    let!(:emp_transaction) { FactoryGirl.create(:offboarding_emp_transaction,
      user_id: user.id,
      employee_id: employee.id) }
    let!(:sp) { FactoryGirl.create(:security_profile) }
    let!(:emp_transaction) { FactoryGirl.create(:onboarding_emp_transaction,
      user_id: user.id,
      employee_id: employee.id) }
    let!(:onboarding_info) { FactoryGirl.create(:onboarding_info,
      emp_transaction_id: emp_transaction.id) }
    let!(:emp_sec_profile) { FactoryGirl.create(:emp_sec_profile,
      security_profile_id: sp.id,
      emp_transaction_id: emp_transaction.id) }
    let!(:email) { TechTableMailer.onboard_instructions(employee).deliver_now }

    it "should queue to send" do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it "should have the right content" do
      expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
      expect(email.to).to include("techtable@opentable.com")
      expect(email.subject).to eq("Mezzo Onboarding Request for #{employee.first_name} #{employee.last_name}")
      expect(email.parts.first.body.raw_source).to include("Onboarding Worker Request")
    end
  end
end
