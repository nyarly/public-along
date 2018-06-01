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
    let(:user) { FactoryGirl.create(:user) }
    let(:emp)  { FactoryGirl.create(:employee, :with_profile) }
    let(:et)   { FactoryGirl.create(:emp_transaction,
                 employee: emp,
                 user_id: user.id,
                 kind: "Security Access") }
    let!(:email) { TechTableMailer.permissions(et).deliver_now }

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
    let(:employee) { FactoryGirl.create(:employee, :with_profile, :with_manager,
                     termination_date: 1.week.from_now) }
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
    let(:employee) { FactoryGirl.create(:employee, :with_profile, :with_manager,
                     termination_date: 2.days.from_now) }
    let!(:email)   { TechTableMailer.offboard_status(employee, results).deliver_now }

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

  describe '.offboard instructions' do
    let(:user) { FactoryGirl.create(:user) }

    context 'with offboard form' do
      let(:forward_to)   { FactoryGirl.create(:employee) }
      let(:employee) do
        FactoryGirl.create(:employee, :with_profile, :with_manager,
         termination_date: 2.days.from_now)
      end
      let(:emp_trans) do
        FactoryGirl.create(:offboarding_emp_transaction,
          user_id: user.id,
          employee_id: employee.id)
      end
      let(:offboard) do
        FactoryGirl.create(:offboarding_info,
          emp_transaction_id: emp_trans.id,
          forward_email_id: forward.id,
          reassign_salesforce_id: forward.id,
          transfer_google_docs_id: forward.id)
      end

      let!(:email) { TechTableMailer.offboard_instructions(employee).deliver_now }

      it 'queues to send' do
        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it 'has the right content' do
        expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
        expect(email.to).to include("techtable@opentable.com")
        expect(email.subject).to eq("Mezzo Offboard Instructions for #{employee.first_name} #{employee.last_name}")
        expect(email.parts.first.body.raw_source).to include("Offboarding Worker Request")
      end
    end

    context 'without offboard form' do
      let(:employee) do
        FactoryGirl.create(:employee, :with_profile, :with_manager,
         termination_date: 2.days.from_now)
      end

      let!(:email) { TechTableMailer.offboard_instructions(employee).deliver_now }

      it 'queues to send' do
        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it 'has the right content' do
        expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
        expect(email.to).to include("techtable@opentable.com")
        expect(email.subject).to eq("Mezzo Offboard Instructions for #{employee.first_name} #{employee.last_name}")
        expect(email.parts.first.body.raw_source).to include("Offboarding Worker Request")
      end
    end

    context 'with termination date' do
      let(:employee) { FactoryGirl.create(:employee, :with_profile, :with_manager,
                       termination_date: 2.days.from_now) }
      let(:forward)   { FactoryGirl.create(:employee) }
      let(:emp_trans) { FactoryGirl.create(:offboarding_emp_transaction,
                        user_id: user.id,
                        employee_id: employee.id) }
      let(:offboard)  { FactoryGirl.create(:offboarding_info,
                        emp_transaction_id: emp_trans.id,
                        forward_email_id: forward.id,
                        reassign_salesforce_id: forward.id,
                        transfer_google_docs_id: forward.id) }
      let!(:email)    { TechTableMailer.offboard_instructions(employee).deliver_now }

      it 'queues to send' do
        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it 'has the right content' do
        expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
        expect(email.to).to include("techtable@opentable.com")
        expect(email.subject).to eq("Mezzo Offboard Instructions for #{employee.first_name} #{employee.last_name}")
        expect(email.parts.first.body.raw_source).to include("Offboarding Worker Request")
      end
    end

    context 'with contract end date' do
      let(:employee) do
        FactoryGirl.create(:employee, :with_profile, :with_manager,
          contract_end_date: Date.today)
      end

      let!(:email) { TechTableMailer.offboard_instructions(employee).deliver_now }

      it 'queues to send' do
        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it 'has the right content' do
        expect(email.from).to eq(["mezzo-no-reply@opentable.com"])
        expect(email.to).to include("techtable@opentable.com")
        expect(email.subject).to eq("Mezzo Offboard Instructions for #{employee.first_name} #{employee.last_name}")
        expect(email.parts.first.body.raw_source).to include("Offboarding Worker Request")
      end
    end
  end

  context "onboard instructions" do
    let(:user)       { FactoryGirl.create(:user) }
    let(:employee) { FactoryGirl.create(:employee, :with_profile, :with_manager,
                     termination_date: 2.days.from_now) }
    let!(:sp)        { FactoryGirl.create(:security_profile) }
    let!(:emp_trans) { FactoryGirl.create(:onboarding_emp_transaction,
                       user_id: user.id,
                       employee_id: employee.id) }
    let!(:onboard)   { FactoryGirl.create(:onboarding_info, emp_transaction_id: emp_trans.id) }
    let!(:e_s_p)     { FactoryGirl.create(:emp_sec_profile,
                       security_profile_id: sp.id,
                       emp_transaction_id: emp_trans.id) }
    let!(:email)     { TechTableMailer.onboard_instructions(emp_trans).deliver_now }

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
