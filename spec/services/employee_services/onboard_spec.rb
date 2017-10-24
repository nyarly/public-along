require 'rails_helper'

describe EmployeeService::Onboard, type: :service do
  let(:manager)   { FactoryGirl.create(:active_employee) }
  let!(:employee) { FactoryGirl.create(:pending_employee,
                   status: "pending",
                   manager: manager) }
  let(:gma)       { double(EmployeeService::GrantManagerAccess) }
  let(:bsps)      { double(EmployeeService::GrantBasicSecProfile) }

  context "succesful process" do
    it "should give basic security profile, manager access, send manager form" do
      expect(EmployeeService::GrantManagerAccess).to receive(:new).with(employee.manager).and_return(gma)
      expect(gma).to receive(:process!)
      expect(EmployeeService::GrantManagerAccess).to receive(:new).with(employee).and_return(gma)
      expect(gma).to receive(:process!)
      expect(EmployeeService::GrantBasicSecProfile).to receive(:new).with(employee).and_return(bsps)
      expect(bsps).to receive(:process!)
      expect(EmployeeWorker).to receive(:perform_async)

      EmployeeService::Onboard.new(employee).process!
    end
  end
end
