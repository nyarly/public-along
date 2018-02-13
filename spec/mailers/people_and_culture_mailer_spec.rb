require 'rails_helper'

RSpec.describe PeopleAndCultureMailer, type: :mailer do
  describe '#code_list_alert' do
    let(:new_location) { FactoryGirl.create(:location,
      code: '123ABV',
      name: 'Paris',
      status: 'Active')}
    let!(:email) { PeopleAndCultureMailer.code_list_alert([new_location]).deliver_now}

    it 'queues to send' do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it 'has the right content' do
      expect(email.from).to eq(['mezzo-no-reply@opentable.com'])
      expect(email.to).to include('pcemail@opentable.com')
      expect(email.subject).to eq('Mezzo Request for Code List Updates')
      expect(email.parts.first.body.raw_source).to include('The following items must be updated in Mezzo:')
      expect(email.parts.first.body.raw_source).to include('New Location:')
    end
  end

  describe '#upcoming_contract_end' do
    let(:contractor) do
      FactoryGirl.create(:contract_worker,
        first_name: 'Fname',
        last_name: 'Lname',
        contract_end_date: Date.new)
    end
    let!(:email) { PeopleAndCultureMailer.upcoming_contract_end(contractor).deliver_now }

    it 'queues to send' do
      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it 'has the right subject' do
      expect(email.subject).to eq('Contract for Fname Lname will expire in 3 weeks')
    end

    it 'has the right body' do
      expect(email.parts.first.body.raw_source).to include("P&C Ops Team: Fname Lname's contract will end in 3 weeks.")
    end
  end
end
