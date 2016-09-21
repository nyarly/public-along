require 'rails_helper'

RSpec.describe EmployeeWorker, type: :worker do
  let!(:employee) { FactoryGirl.create(:employee, manager_id: manager.employee_id) }
  let!(:manager) { FactoryGirl.create(:employee) }
  let(:worker) { EmployeeWorker.new }
  let(:mailer) { double(ManagerMailer) }

  it "should perform right away" do
    EmployeeWorker.perform_async("onboard", employee.id)

    expect(EmployeeWorker.jobs.size).to eq(1)
  end

  it "should find Manager" do
    allow(ManagerMailer).to receive(:permissions).and_return(mailer)
    allow(mailer).to receive(:deliver_now)

    expect(Employee).to receive(:find_by).with(employee_id: employee.manager_id).and_call_original

    worker.perform("onboard", employee.id)
  end

  it "should send the right Mailer for onboard action" do
    expect(ManagerMailer).to receive(:permissions).with(manager, employee, "Onboarding").and_return(mailer)
    expect(mailer).to receive(:deliver_now)

    worker.perform("onboard", employee.id)
  end

  it "should send the right Mailer for job change" do
    expect(ManagerMailer).to receive(:permissions).with(manager, employee, "Security Access").and_return(mailer)
    expect(mailer).to receive(:deliver_now)

    worker.perform("job_change", employee.id)
  end

end
