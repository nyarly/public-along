require "rails_helper"

RSpec.describe ManagerMailer, type: :mailer do
  let(:ceo)       { FactoryGirl.create(:employee, email: 'ceo@opentable.com') }
  let(:manager)   { FactoryGirl.create(:employee, email: 'manager@opentable.com', manager: ceo) }
  let(:employee)  { FactoryGirl.create(:employee, manager: manager) }

  before do
    FactoryGirl.create(:profile,
      adp_employee_id: "111111",
      employee: ceo)

    FactoryGirl.create(:profile,
      employee: manager,
      adp_employee_id: "654321")

    FactoryGirl.create(:profile,
      employee: employee,
      adp_employee_id: '123456')
  end

  describe '#reminder' do
    context 'when sent to manager' do
      subject(:reminder_email) { ManagerMailer.reminder(manager, employee, 'reminder') }

      before do
        reminder_email.deliver_now
      end

      it 'queues to send' do
        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it 'is sent from mezzo' do
        expect(reminder_email.from).to eq(['mezzo-no-reply@opentable.com'])
      end

      it 'is sent to the manager' do
        expect(reminder_email.to).to eq(['manager@opentable.com'])
      end

      it 'has the correct subject' do
        expect(reminder_email.subject)
          .to eq("Urgent: Mezzo Onboarding Form Due Tomorrow for #{employee.first_name} #{employee.last_name}")
      end

      it 'has the correct txt body' do
        expect(reminder_email.text_part.body)
          .to include('Follow the link below to complete the employee event form')
      end

      it 'has the correct html body' do
        expect(reminder_email.html_part.body)
          .to include('Follow the link below to complete the employee event form')
      end

      it 'includes a mezzo link for the manager' do
        expect(reminder_email.text_part.body).to include('user_emp_id=654321')
        expect(reminder_email.html_part.body).to include('user_emp_id=654321')
      end
    end

    context "when escalated to manager's manager" do
      subject(:escalation_email) { ManagerMailer.reminder(ceo, employee, 'escalation') }

      before do
        escalation_email.deliver_now
      end

      it 'queues to send' do
        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it 'is sent from mezzo' do
        expect(escalation_email.from).to eq(['mezzo-no-reply@opentable.com'])
      end

      it "is sent to the manager's manager" do
        expect(escalation_email.to).to eq(['ceo@opentable.com'])
      end

      it 'has the correct subject' do
        expect(escalation_email.subject)
          .to eq("Urgent: Mezzo Onboarding Form Due Tomorrow for #{employee.first_name} #{employee.last_name}")
      end

      it 'has the correct txt body' do
        expect(escalation_email.text_part.body)
          .to include('Follow the link below to complete the employee event form')
      end

      it 'has the correct html body' do
        expect(escalation_email.html_part.body)
          .to include('Follow the link below to complete the employee event form')
      end

      it "includes a mezzo link for the manager's manager" do
        expect(escalation_email.text_part.body).to include('user_emp_id=111111')
        expect(escalation_email.html_part.body).to include('user_emp_id=111111')
      end
    end
  end

  describe '#permissions' do
    context 'when security access form' do
      subject(:email) { ManagerMailer.permissions('Security Access', manager, employee) }

      before do
        email.deliver_now
      end

      it 'queues to send' do
        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it 'is sent from mezzo' do
        expect(email.from).to eq(['mezzo-no-reply@opentable.com'])
      end

      it 'is sent to the manager' do
        expect(email.to).to eq(['manager@opentable.com'])
      end

      it 'has the correct subject' do
        expect(email.subject)
          .to eq("IMMEDIATE ACTION REQUIRED: Employee Event Form for #{employee.first_name} #{employee.last_name}")
      end

      it 'has the correct txt body' do
        expect(email.text_part.body)
          .to include('Follow the link below to complete the employee event form')
      end

      it 'has the correct html body' do
        expect(email.html_part.body)
          .to include('Follow the link below to complete the employee event form')
      end
    end

    context 'when onboarding form' do
      subject(:email) { ManagerMailer.permissions('Onboarding', manager, employee) }

      before do
        email.deliver_now
      end

      it 'queues to send' do
        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it 'is sent from mezzo' do
        expect(email.from).to eq(['mezzo-no-reply@opentable.com'])
      end

      it 'is sent to the manager' do
        expect(email.to).to eq(['manager@opentable.com'])
      end

      it 'has the correct subject' do
        expect(email.subject)
          .to eq("IMMEDIATE ACTION REQUIRED: Employee Event Form for #{employee.first_name} #{employee.last_name}")
      end

      it 'has the correct due date in the txt body' do
        expect(email.text_part.body)
          .to include("You must complete this form by #{employee.onboarding_due_date.try(:strftime, "%B %e, %Y")}")
      end

      it 'has the correct due date in the html body' do
        expect(email.html_part.body)
          .to include("You must complete this form by #{employee.onboarding_due_date.try(:strftime, "%B %e, %Y")}")
      end
    end

    context 'when onboarding form from event' do
      subject(:email) { ManagerMailer.permissions('Onboarding', worker.manager, worker, event: event) }

      let(:rehire_json) { File.read(Rails.root.to_s + '/spec/fixtures/adp_rehire_event.json') }
      let(:event)       { AdpEvent.new(status: 'New', json: rehire_json) }
      let(:worker)      { EmployeeProfile.new.build_employee(event) }

      before do
        FactoryGirl.create(:worker_type, code: 'FTR')

        email.deliver_now
      end

      it 'queues to send' do
        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it 'is sent from mezzo' do
        expect(email.from).to eq(['mezzo-no-reply@opentable.com'])
      end

      it 'is sent to the manager' do
        expect(email.to).to eq(['manager@opentable.com'])
      end

      it 'has the correct subject' do
        expect(email.subject)
          .to eq('IMMEDIATE ACTION REQUIRED: Employee Event Form for Bob Fakename')
      end

      it 'has the correct due date in the txt body' do
        expect(email.text_part.body)
          .to include('You must complete this form by August 24, 2018')
      end

      it 'has the correct due date in the html body' do
        expect(email.html_part.body)
          .to include('You must complete this form by August 24, 2018')
      end
    end

    context 'when offboarding form' do
      subject(:email) { ManagerMailer.permissions('Offboarding', manager, worker) }

      let(:worker) do
        FactoryGirl.create(:active_employee,
          termination_date: 1.week.from_now,
          manager: manager)
      end

      before do
        email.deliver_now
      end

      it 'queues to send' do
        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it 'is sent from mezzo' do
        expect(email.from).to eq(['mezzo-no-reply@opentable.com'])
      end

      it 'is sent to the manager' do
        expect(email.to).to eq(['manager@opentable.com'])
      end

      it 'has the correct subject' do
        expect(email.subject)
          .to eq("IMMEDIATE ACTION REQUIRED: Employee Event Form for #{worker.first_name} #{worker.last_name}")
      end

      it 'includes a link for the manager' do
        expect(email.text_part.body).to include('user_emp_id=654321')
        expect(email.html_part.body).to include('user_emp_id=654321')
      end

      it 'has the correct due date in the txt body' do
        expect(email.text_part.body)
          .to include("You must complete this form by noon on #{worker.termination_date.try(:strftime, "%b %e, %Y")}")
      end

      it 'has the correct due date in the html body' do
        expect(email.html_part.body)
          .to include("You must complete this form by noon on #{worker.termination_date.try(:strftime, "%b %e, %Y")}")
      end
    end

    context 'when offboarding contractor' do
      subject(:email) { ManagerMailer.permissions('Offboarding', manager, worker) }

      let(:worker) do
        FactoryGirl.create(:contract_worker,
          contract_end_date: 1.week.from_now,
          manager: manager)
      end

      before do
        email.deliver_now
      end

      it 'queues to send' do
        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it 'is sent from mezzo' do
        expect(email.from).to eq(['mezzo-no-reply@opentable.com'])
      end

      it 'is sent to the manager' do
        expect(email.to).to eq(['manager@opentable.com'])
      end

      it 'has the correct subject' do
        expect(email.subject)
          .to eq("IMMEDIATE ACTION REQUIRED: Employee Event Form for #{worker.first_name} #{worker.last_name}")
      end

      it 'includes a link for the manager' do
        expect(email.text_part.body).to include('user_emp_id=654321')
        expect(email.html_part.body).to include('user_emp_id=654321')
      end

      it 'has the correct due date in the txt body' do
        expect(email.text_part.body)
          .to include("This worker's contract expires on #{worker.contract_end_date.try(:strftime, "%b %e, %Y")}")
      end

      it 'has the correct due date in the html body' do
        expect(email.html_part.body)
          .to include("This worker's contract expires on #{worker.contract_end_date.try(:strftime, "%b %e, %Y")}")
      end
    end
  end
end
