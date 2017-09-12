require 'rails_helper'

RSpec.describe ReminderWorker, type: :worker do
  let!(:manager)   { FactoryGirl.create(:employee,
                     email: "manager@example.com")}
  let!(:m_profile) { FactoryGirl.create(:profile,
                     employee: manager,
                     adp_employee_id: "12345")}
  let!(:employee)  { FactoryGirl.create(:employee)}
  let!(:profile)   { FactoryGirl.create(:profile,
                     employee: employee,
                     manager_id: "12345")}
  let!(:mailer)    { double(ManagerMailer) }
  let(:worker)     { ReminderWorker.new }

  it "should perform right away" do
    ReminderWorker.perform_async(manager, employee)
    expect(ReminderWorker.jobs.size).to eq(1)
  end

  it "should send the right mailer" do
    allow(ManagerMailer).to receive(:permissions).and_return(mailer)
    allow(mailer).to receive(:deliver_now)
    expect(Employee).to receive(:find_by_employee_id).with(employee.manager_id).and_call_original
    worker.perform(employee_id, manager_id)
  end

end
