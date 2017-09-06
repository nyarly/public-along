require 'rails_helper'

RSpec.describe EmployeeChangeWorker, type: :worker do
  let(:service) { double(AdpService::Workers) }
  let(:worker) { EmployeeChangeWorker.new }
  let(:employee) { FactoryGirl.create(:employee) }

  it "should perform right away" do
    EmployeeChangeWorker.perform_async(employee.id)
    expect(EmployeeChangeWorker.jobs.size).to eq(1)
  end

  it "should instantiate AdpService::Workers class and call #look_ahead with employee" do
    expect(AdpService::Workers).to receive(:new).and_return(service)
    expect(service).to receive(:look_ahead).with(employee)

    worker.perform(employee.id)
  end
end
