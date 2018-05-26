require 'rails_helper'
require 'rake'

describe 'notification rake tasks', type: :tasks do

  before do
    Rake.application = Rake::Application.new
    Rake.application.rake_require 'lib/tasks/notify', [Rails.root.to_s], ''
    Rake::Task.define_task :environment
  end

  describe 'notify:hr_temp_expiration' do
    let(:mailer) { double(PeopleAndCultureMailer) }

    before do
      allow(SendHrTempExpirationNotice).to receive(:perform_async)
    end

    context 'when when there are contracts ending in 3 weeks' do
      let!(:contractor) do
        FactoryGirl.create(:temp_worker,
          first_name: 'Fname',
          last_name: 'Lname',
          status: 'active',
          contract_end_date: Date.new(2018, 2, 26))
      end

      before do
        Timecop.freeze(Time.new(2018, 2, 5, 0, 0, 0, '+00:00'))

        Rake::Task['notify:hr_temp_expiration'].invoke
      end

      after do
        Timecop.return
      end

      it 'sends the email' do
        expect(SendHrTempExpirationNotice).to have_received(:perform_async)
          .with(contractor.id)
      end
    end

    context 'when there are no contracts ending in 3 weeks' do
      let!(:contractor) do
        FactoryGirl.create(:temp_worker,
          first_name: 'Fname',
          last_name: 'Lname',
          status: 'active',
          contract_end_date: Date.new(2018, 2, 28))
      end

      before do
        Timecop.freeze(Time.new(2018, 2, 5, 2, 0, 0, '+00:00'))

        Rake::Task['notify:hr_temp_expiration'].invoke
      end

      after do
        Timecop.return
      end

      it 'does not send the email' do
        expect(SendHrTempExpirationNotice).not_to have_received(:perform_async)
      end
    end
  end

  describe 'notify:manager_contract_expiration' do
    let!(:manager) { FactoryGirl.create(:employee) }

    let!(:contractor) do
      FactoryGirl.create(:contract_worker,
        status: 'active',
        request_status: 'none',
        contract_end_date: Date.new(2017, 12, 1),
        termination_date: nil,
        manager: manager)
    end

    let!(:offboarding) do
      FactoryGirl.create(:contract_worker,
        status: 'active',
        contract_end_date: Date.new(2017, 11, 11),
        termination_date: Date.new(2017, 12, 1),
        manager: manager)
    end

    before do
      allow(SendManagerOffboardForm).to receive(:perform_async)

      Timecop.freeze(Time.new(2017, 11, 17, 17, 0, 0, '+00:00'))
      Rake::Task['notify:manager_contract_expiration'].invoke
    end

    after do
      Timecop.return
    end

    it 'reminds manager of worker with contract end date in two weeks' do
      expect(SendManagerOffboardForm).to have_received(:perform_async)
        .with(contractor.id)
    end

    it 'it does not send a reminder for contractor in offboard process' do
      expect(SendManagerOffboardForm).not_to have_received(:perform_async)
        .with(offboarding.id)
    end
  end
end
