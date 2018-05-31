require 'rails_helper'

RSpec.describe SendManagerOffboardForm, type: :worker do
  let(:manager)   { FactoryGirl.create(:regular_employee) }
  let(:employee)  { FactoryGirl.create(:contract_worker, manager: manager) }
  let(:mailer)    { double(ManagerMailer) }

  before do
    allow(ManagerMailer).to receive(:permissions).and_return(mailer)
    allow(mailer).to receive(:deliver_now)
  end

  it 'enqueues a worker' do
    SendManagerOffboardForm.perform_async(employee.id)
    expect(SendManagerOffboardForm.jobs.size).to eq(1)
  end

  it 'sends the manager offboarding form' do
    SendManagerOffboardForm.new.perform(employee.id)

    expect(ManagerMailer).to have_received(:permissions)
      .with('Offboarding', manager, employee)
    expect(mailer).to have_received(:deliver_now)
  end

  it 'updates the worker request status' do
    SendManagerOffboardForm.new.perform(employee.id)

    expect(employee.reload.request_status).to eq('waiting')
  end
end
