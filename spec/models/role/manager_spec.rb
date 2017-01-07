require 'rails_helper'
require 'cancan/matchers'

describe Role::Manager, :type => :model do
  let :user do FactoryGirl.create(:user, :manager) end

  describe 'abilities' do
    it_should_behave_like "role abilities", Employee, [:read]
    it_should_behave_like "role abilities", EmpTransaction, [:new, :show, :create]
    it_should_behave_like "role abilities", ManagerEntry, [:create]
  end
end
