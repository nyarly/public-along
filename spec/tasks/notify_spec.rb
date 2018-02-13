require 'rails_helper'
require 'rake'

describe 'notification rake tasks', type: :tasks do
  describe 'notify:hr_contract_end' do
    let(:mailer) { double(PeopleAndCultureMailer) }

    before do
      Rake.application = Rake::Application.new
      Rake.application.rake_require 'lib/tasks/notify', [Rails.root.to_s], ''
      Rake::Task.define_task :environment
      allow(PeopleAndCultureMailer).to receive(:upcoming_contract_end).and_return(mailer)
      allow(mailer).to receive(:deliver_now)
    end

    context 'when when there are contracts ending in 3 weeks' do
      let!(:contractor) do
        FactoryGirl.create(:contract_worker,
          first_name: 'Fname',
          last_name: 'Lname',
          status: 'active',
          contract_end_date: Date.new(2018, 2, 26))
      end

      before do
        Timecop.freeze(Time.new(2018, 2, 5, 0, 0, 0, '+00:00'))
      end

      after do
        Timecop.return
      end

      it 'sends the email' do
        expect(PeopleAndCultureMailer).to receive(:upcoming_contract_end).with(contractor).and_return(mailer)
        expect(mailer).to receive(:deliver_now)
        Rake::Task['notify:hr_contract_end'].invoke
      end
    end

    context 'when there are no contracts ending in 3 weeks' do
      let!(:contractor) do
        FactoryGirl.create(:contract_worker,
          first_name: 'Fname',
          last_name: 'Lname',
          status: 'active',
          contract_end_date: Date.new(2018, 2, 28))
      end

      before do
        Timecop.freeze(Time.new(2018, 2, 5, 2, 0, 0, '+00:00'))
        allow(PeopleAndCultureMailer).to receive(:upcoming_contract_end).and_return(mailer)
        allow(mailer).to receive(:deliver_now)
      end

      after do
        Timecop.return
      end

      it 'does not send the email' do
        expect(PeopleAndCultureMailer).not_to receive(:upcoming_contract_end)
        Rake::Task['notify:hr_contract_end'].invoke
      end
    end
  end
end
