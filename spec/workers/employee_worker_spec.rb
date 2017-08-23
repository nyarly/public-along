require 'rails_helper'

RSpec.describe EmployeeWorker, type: :worker do
  let!(:manager) { FactoryGirl.create(:regular_employee) }
  let!(:employee) { FactoryGirl.create(:employee) }
  let!(:profile) { FactoryGirl.create(:profile,
    employee: employee,
    manager_id: manager.employee_id)}
  let(:worker) { EmployeeWorker.new }
  let(:mailer) { double(ManagerMailer) }

  it "should perform right away" do
    EmployeeWorker.perform_async("Onboarding", employee_id: employee.id)

    expect(EmployeeWorker.jobs.size).to eq(1)
  end

  it "should find Manager" do
    allow(ManagerMailer).to receive(:permissions).and_return(mailer)
    allow(mailer).to receive(:deliver_now)

    expect(Employee).to receive(:find_by_employee_id).with(employee.manager_id).and_call_original

    worker.perform("Onboarding", employee_id: employee.id)
  end

  it "should send the right Mailer for Onboarding action" do
    expect(ManagerMailer).to receive(:permissions).with("Onboarding", manager, employee).and_return(mailer)
    expect(mailer).to receive(:deliver_now)

    worker.perform("Onboarding", employee_id: employee.id)
  end

  it "should send the right Mailer for job change" do
    expect(ManagerMailer).to receive(:permissions).with("Security Access", manager, employee).and_return(mailer)
    expect(mailer).to receive(:deliver_now)

    worker.perform("Security Access", employee_id: employee.id)
  end

  it "should send the right mailer for rehire" do
    expect(ManagerMailer).to receive(:permissions).with("Onboarding", manager, employee, ).and_return(mailer)

  end

end
