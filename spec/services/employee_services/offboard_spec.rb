require 'rails_helper'

describe EmployeeService::Offboard, type: :service do
  context "#prepare_termination" do
    let(:employee) { FactoryGirl.create(:employee, :with_manager,
                     termination_date: 1.week.from_now) }
    let(:mailer)   { double(TechTableMailer) }

    it "should send techtable and manager mailers" do
      expect(TechTableMailer).to receive(:offboard_notice).with(employee).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      expect(EmployeeWorker).to receive(:perform_async).with("Offboarding", employee_id: employee.id)

      EmployeeService::Offboard.new(employee).prepare_termination
    end
  end
end
