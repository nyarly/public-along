require 'rails_helper'

describe EmployeeService::Onboard, type: :service do
  let(:ads)       { double(ActiveDirectoryService) }
  let(:bsps)      { double(EmployeeService::GrantBasicSecProfile) }
  let(:gma)       { double(EmployeeService::GrantManagerAccess) }
  let(:manager)   { FactoryGirl.create(:active_employee) }
  let(:employee) do
    FactoryGirl.create(:pending_employee, manager: manager)
  end

  before do
    FactoryGirl.create(:profile, :with_valid_ou, employee: employee)

    allow(ActiveDirectoryService).to receive(:new).and_return(ads)
    allow(ads).to receive(:create_disabled_accounts)
    allow(ads).to receive(:update)
    allow(UpdateEmailWorker).to receive(:perform_async)
    allow(EmployeeService::GrantManagerAccess).to receive(:new).and_return(gma)
    allow(gma).to receive(:process!)
    allow(EmployeeService::GrantBasicSecProfile).to receive(:new).and_return(bsps)
    allow(bsps).to receive(:process!)
  end

  describe '#new_worker' do
    before do
      EmployeeService::Onboard.new(employee).new_worker
    end

    it 'creates an active directory account for the new worker' do
      expect(ads).to have_received(:create_disabled_accounts).with([employee])
    end

    it 'updates worker email in ADP' do
      expect(UpdateEmailWorker).to have_received(:perform_async).with(employee.id)
    end

    it 'checks access for new worker manager' do
      expect(EmployeeService::GrantManagerAccess).to have_received(:new).with(manager)
    end

    it 'checks worker manager access' do
      expect(EmployeeService::GrantManagerAccess).to have_received(:new).with(employee)
    end

    it 'grants basic access' do
      expect(EmployeeService::GrantBasicSecProfile).to have_received(:new).with(employee)
    end
  end

  describe '#re_onboard' do
    before do
      EmployeeService::Onboard.new(employee).re_onboard
    end

    it 'creates an active directory account for the new worker' do
      expect(ads).to have_received(:update).with([employee])
    end

    it 'updates worker email in ADP' do
      expect(UpdateEmailWorker).to have_received(:perform_async).with(employee.id)
    end

    it 'checks access for new worker manager' do
      expect(EmployeeService::GrantManagerAccess).to have_received(:new).with(manager)
    end

    it 'checks worker manager access' do
      expect(EmployeeService::GrantManagerAccess).to have_received(:new).with(employee)
    end

    it 'grants basic access' do
      expect(EmployeeService::GrantBasicSecProfile).to have_received(:new).with(employee)
    end
  end
end
