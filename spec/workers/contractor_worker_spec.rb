require 'rails_helper'

RSpec.describe ContractorWorker, type: :worker do
  let(:manager)  { FactoryGirl.create(:regular_employee) }
  let(:employee) { FactoryGirl.create(:contract_worker,
                   manager: manager) }
  let(:mailer)   { double(ManagerMailer) }
  let(:worker)   { ContractorWorker.new }

  it "should perform right away" do
    ContractorWorker.perform_async(employee.id)
    expect(ContractorWorker.jobs.size).to eq(1)
  end

  it "should send the manager offboarding form" do
    expect(ManagerMailer).to receive(:permissions).with("Offboarding", manager, employee).and_return(mailer)
    expect(mailer).to receive(:deliver_now)
    worker.perform(employee.id)
  end
end
