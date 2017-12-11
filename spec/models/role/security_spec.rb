require 'rails_helper'
require 'cancan/matchers'

describe Role::Security, type: :model do
  let :user do FactoryGirl.create(:user, :security) end

  describe 'abilities' do
    it_should_behave_like 'role abilities', Employee, [:read, :direct_reports, :autocomplete_name]
    it_should_behave_like 'role abilities', MachineBundle, [:read]
    it_should_behave_like 'role abilities', Location, [:read]
    it_should_behave_like 'role abilities', Department, [:read]
    it_should_behave_like 'role abilities', DeptSecProf, [:read]
    it_should_behave_like 'role abilities', SecurityProfile, [:read]
    it_should_behave_like 'role abilities', SecProfAccessLevel, [:read]
    it_should_behave_like 'role abilities', AccessLevel, [:read]
    it_should_behave_like 'role abilities', Application, [:read]
    it_should_behave_like 'role abilities', EmpTransaction, [:read]
    it_should_behave_like 'role abilities', EmpSecProfile, [:read]
    it_should_behave_like 'role abilities', ParentOrg, [:read]
    it_should_behave_like 'role abilities', WorkerType, [:read]
    it_should_behave_like 'role abilities', Profile, [:read]
  end
end
