require 'rails_helper'

RSpec.describe EmployeeWorker, type: :worker do
  let!(:employee) { FactoryGirl.create(:employee, manager_id: manager.employee_id) }
  let!(:manager) { FactoryGirl.create(:employee) }
  let!(:new_manager) { FactoryGirl.create(:employee, employee_id: "173wM2n2g3riD")}
  let!(:termed_worker) { FactoryGirl.create(:employee, manager_id: manager.employee_id, hire_date: 5.years.ago, termination_date: 3.years.ago )}
  let(:worker) { EmployeeWorker.new }
  let(:mailer) { double(ManagerMailer) }

  it "should perform right away" do
    EmployeeWorker.perform_async(:create, employee)

    expect(EmployeeWorker.jobs.size).to eq(1)
  end

  it "should find Manager" do
    allow(ManagerMailer).to receive(:permissions).and_return(mailer)
    allow(mailer).to receive(:deliver_now)

    expect(Employee).to receive(:find_by).with(employee_id: employee.manager_id).and_call_original

    worker.perform(:create, employee)
  end

  it "should send the right Mailer for create action" do
    expect(ManagerMailer).to receive(:permissions).with(manager, employee, "Onboarding").and_return(mailer)
    expect(mailer).to receive(:deliver_now)

    worker.perform(:create, employee)
  end

  it "should send the right Mailer for a rehire" do
    termed_worker.assign_attributes(hire_date: Date.today, termination_date: nil)

    expect(ManagerMailer).to receive(:permissions).with(manager, termed_worker, "Onboarding").and_return(mailer)
    expect(mailer).to receive(:deliver_now)

    worker.perform(:update, termed_worker)
  end

  it "should send the right Mailer for a business title change" do
    employee.assign_attributes(business_title: "new business title")

    expect(ManagerMailer).to receive(:permissions).with(manager, employee, "Security Access").and_return(mailer)
    expect(mailer).to receive(:deliver_now)

    worker.perform(:update, employee)
  end

  it "should not send the Mailer if business title does not change" do
    old_title = employee.business_title
    employee.assign_attributes(business_title: old_title)

    expect(ManagerMailer).to_not receive(:permissions)

    worker.perform(:update, employee)
  end

  it "should send the right Mailer for a manager change" do
    employee.assign_attributes(manager_id: "173wM2n2g3riD")

    expect(ManagerMailer).to receive(:permissions).with(new_manager, employee, "Security Access").and_return(mailer)
    expect(mailer).to receive(:deliver_now)

    worker.perform(:update, employee)
  end

end
