require 'rails_helper'

describe EmployeeService::GrantBasicSecProfile, type: :sevice do
  let!(:regular)  { FactoryGirl.create(:security_profile, name: 'Basic Regular Worker Profile') }
  let!(:temp)     { FactoryGirl.create(:security_profile, name: 'Basic Temp Worker Profile') }
  let!(:contract) { FactoryGirl.create(:security_profile, name: 'Basic Contract Worker Profile') }
  let!(:reg_wt)   { FactoryGirl.create(:worker_type, kind: 'Regular') }
  let!(:temp_wt)  { FactoryGirl.create(:worker_type, kind: 'Temporary') }
  let!(:cont_wt)  { FactoryGirl.create(:worker_type, kind: 'Contractor') }

  describe '#process!' do
    context 'with a regular worker' do
      subject(:service) { EmployeeService::GrantBasicSecProfile.new(employee).process! }

      let(:employee) { FactoryGirl.create(:employee, status: 'pending') }

      before do
        FactoryGirl.create(:profile,
          employee: employee,
          worker_type: reg_wt)
      end

      it 'should add the regular security profile' do
        expect(service).to include(regular)
        expect(service).not_to include(temp)
        expect(service).not_to include(contract)
        expect(employee.security_profiles).to eq([regular])
      end
    end

    context 'with a temp worker' do
      subject(:service) { EmployeeService::GrantBasicSecProfile.new(employee).process! }

      let(:employee) { FactoryGirl.create(:employee, status: 'pending') }

      before do
        FactoryGirl.create(:profile,
          employee: employee,
          worker_type: temp_wt)
      end

      it 'should add the temporary security profile' do
        expect(service).to include(temp)
        expect(service).not_to include(contract)
        expect(service).not_to include(regular)
        expect(employee.security_profiles).to eq([temp])
      end
    end

    context 'with a contract worker' do
      let(:service) { EmployeeService::GrantBasicSecProfile.new(employee).process! }

      let(:employee) { FactoryGirl.create(:employee, status: 'pending') }

      before do
        FactoryGirl.create(:profile,
          employee: employee,
          worker_type: cont_wt)
      end

      it 'should add the temporary security profile' do
        expect(service).to include(contract)
        expect(service).not_to include(regular)
        expect(service).not_to include(temp)
        expect(employee.security_profiles).to eq([contract])
      end
    end

    context 'with a rehire' do
      subject(:service) { EmployeeService::GrantBasicSecProfile.new(rehire).process! }

      let(:rehire) { FactoryGirl.create(:employee, status: 'pending') }

      before do
        FactoryGirl.create(:profile,
          employee: rehire,
          profile_status: 'terminated',
          worker_type: reg_wt,
          management_position: false,
          primary: false)

        FactoryGirl.create(:profile,
          employee: rehire,
          profile_status: 'pending',
          worker_type: cont_wt,
          management_position: true,
          primary: true)
      end

      it 'should give basic security profile for new worker type' do
        expect(service).to include(contract)
        expect(service).not_to include(regular)
        expect(service).not_to include(temp)
        expect(rehire.security_profiles).to eq([contract])
      end
    end
  end
end
