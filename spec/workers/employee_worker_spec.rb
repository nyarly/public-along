require 'rails_helper'

RSpec.describe EmployeeWorker, type: :worker do
  let(:manager) { FactoryGirl.create(:employee,
    email: "manager@opentable.com") }
  let!(:man_profile) { FactoryGirl.create(:active_profile,
    employee: manager,
    adp_employee_id: "654321")}
  let!(:employee) { FactoryGirl.create(:employee, manager: manager) }
  let(:worker) { EmployeeWorker.new }
  let(:mailer) { double(ManagerMailer) }
  let(:rehire_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_rehire_event.json") }
  let(:event) { FactoryGirl.create(:adp_event, status: "New", json: rehire_json) }
  let!(:worker_type) { FactoryGirl.create(:worker_type, code: "FTR") }
  let(:profiler) { EmployeeProfile.new }
  let(:potential_employee) { profiler.build_employee(event) }

  it "should perform right away" do
    EmployeeWorker.perform_async("Onboarding", employee_id: employee.id)

    expect(EmployeeWorker.jobs.size).to eq(1)
  end

  it "should send the right Mailer for Onboarding action" do
    expect(ManagerMailer).to receive(:permissions).with("Onboarding", manager, employee).and_return(mailer)
    expect(mailer).to receive(:deliver_now)

    worker.perform("Onboarding", {"employee_id"=>employee.id})
  end

  it "should send the right Mailer for job change" do
    expect(ManagerMailer).to receive(:permissions).with("Security Access", manager, employee).and_return(mailer)
    expect(mailer).to receive(:deliver_now)

    worker.perform("Security Access", {"employee_id"=>employee.id})
  end

  it "should send the right mailer for rehire" do
    expect(ManagerMailer).to receive(:permissions).with("Onboarding", manager, potential_employee, event: event).and_return(mailer)
    expect(mailer).to receive(:deliver_now)

    expect(EmployeeProfile).to receive(:new).and_return(profiler)
    expect(AdpEvent).to receive(:find).with(event.id).and_return(event)
    expect(profiler).to receive(:build_employee).with(event).and_return(potential_employee)
    expect(potential_employee).to receive(:manager).and_return(manager)

    worker.perform("Onboarding", {"event_id"=>event.id})
  end

end
