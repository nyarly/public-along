require 'rails_helper'
require 'cancan/matchers'

describe Role::Helpdesk, :type => :model do
  let :user do FactoryGirl.create(:user, :helpdesk) end

  describe 'abilities' do
    it_should_behave_like "role abilities", MachineBundle, [:manage]
    it_should_behave_like "role abilities", DeptSecProf, [:manage]
    it_should_behave_like "role abilities", SecurityProfile, [:manage]
    it_should_behave_like "role abilities", SecProfAccessLevel, [:manage]
    it_should_behave_like "role abilities", AccessLevel, [:manage]
    it_should_behave_like "role abilities", Application, [:manage]
    it_should_behave_like "role abilities", EmpTransaction, [:new, :read]
    it_should_behave_like "role abilities", Employee, [:read, :autocomplete_name]
    it_should_behave_like "role abilities", EmpSecProfile, [:read]
    it_should_behave_like "role abilities", Department, [:read]
    it_should_behave_like "role abilities", Email, [:create]
    it_should_behave_like "role abilities", :new_hire, [:read]
    it_should_behave_like "role abilities", :offboard, [:read]
    it_should_behave_like "role abilities", :inactive, [:read]
  end
end
