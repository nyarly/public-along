require 'rails_helper'

describe EmployeeService::Onboard, type: :service do
  let(:manager)   { FactoryGirl.create(:active_employee) }
  let!(:employee) { FactoryGirl.create(:pending_employee,
                    status: 'pending',
                    manager: manager) }
  let!(:profile)  { FactoryGirl.create(:profile, :with_valid_ou,
                    employee: employee) }
  let(:gma)       { double(EmployeeService::GrantManagerAccess) }
  let(:bsps)      { double(EmployeeService::GrantBasicSecProfile) }
  let(:ads)       { double(ActiveDirectoryService) }

  context '#new_worker' do
    it 'prepares new hire' do
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:create_disabled_accounts).with([employee])
      EmployeeService::Onboard.new(employee).new_worker
    end
  end

  context '#re_onboard' do
    it 'prepares rehire' do
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:update).with([employee])
      EmployeeService::Onboard.new(employee).re_onboard
    end
  end

  context '#process_security_profiles' do
    it 'grants security access' do
      expect(EmployeeService::GrantManagerAccess).to receive(:new).with(employee.manager).and_return(gma)
      expect(gma).to receive(:process!)
      expect(EmployeeService::GrantManagerAccess).to receive(:new).with(employee).and_return(gma)
      expect(gma).to receive(:process!)
      expect(EmployeeService::GrantBasicSecProfile).to receive(:new).with(employee).and_return(bsps)
      expect(bsps).to receive(:process!)

      EmployeeService::Onboard.new(employee).process_security_profiles
    end
  end
end
