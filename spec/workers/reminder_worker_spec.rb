require 'rails_helper'

RSpec.describe ReminderWorker, type: :worker do
  let!(:manager)   { FactoryGirl.create(:employee,
                     email: "manager@example.com")}
  let!(:m_profile) { FactoryGirl.create(:profile,
                     employee: manager,
                     adp_employee_id: "654321")}
  let!(:employee)  { FactoryGirl.create(:employee)}
  let!(:profile)   { FactoryGirl.create(:profile,
                     employee: employee,
                     manager_id: "654321")}
  let!(:mailer)    { double(ManagerMailer) }
  let(:worker)     { ReminderWorker.new }
  let(:profiler)   { EmployeeProfile.new }
  let!(:json)      { File.read(Rails.root.to_s+"/spec/fixtures/adp_rehire_event.json") }
  let!(:event)     { FactoryGirl.create(:adp_event,
                     kind: "worker.rehire",
                     status: "New",
                     json: json) }
  let!(:reg_wt)    { FactoryGirl.create(:worker_type,
                     code: "FTR")}

  it "should perform right away" do
    ReminderWorker.perform_async(manager, employee)
    expect(ReminderWorker.jobs.size).to eq(1)
  end

  it "should send the right mailer for hire" do
    allow(ManagerMailer).to receive(:reminder).and_return(mailer)
    allow(mailer).to receive(:deliver_now)
    expect(Employee).to receive(:find_by_employee_id).with(employee.manager_id).and_call_original
    worker.perform({"employee_id"=>employee.id})
  end

  it "should send the right mailer for rehire" do
    allow(ManagerMailer).to receive(:reminder).and_return(mailer)
    allow(mailer).to receive(:deliver_now)
    expect(EmployeeProfile).to receive(:new).and_return(profiler)
    worker.perform({"event_id"=>event.id})
  end

end
