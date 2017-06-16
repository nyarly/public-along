require 'rails_helper'
require 'cancan/matchers'

describe Role::Admin, :type => :model do
  let :user do FactoryGirl.create(:user, :admin) end

  describe 'abilities' do
    it_should_behave_like "role abilities", Employee, [:manage]
    it_should_behave_like "role abilities", MachineBundle, [:manage]
    it_should_behave_like "role abilities", Location, [:manage]
    it_should_behave_like "role abilities", Department, [:manage]
    it_should_behave_like "role abilities", DeptSecProf, [:manage]
    it_should_behave_like "role abilities", SecurityProfile, [:manage]
    it_should_behave_like "role abilities", SecProfAccessLevel, [:manage]
    it_should_behave_like "role abilities", AccessLevel, [:manage]
    it_should_behave_like "role abilities", Application, [:manage]
    it_should_behave_like "role abilities", EmpTransaction, [:manage]
    it_should_behave_like "role abilities", EmpSecProfile, [:manage]
    it_should_behave_like "role abilities", ParentOrg, [:manage]
    it_should_behave_like "role abilities", WorkerType, [:manage]
    it_should_behave_like "role abilities", Email, [:create]
  end
end
