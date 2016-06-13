require 'rails_helper'
require 'cancan/matchers'

describe Role::Manager, :type => :model do
  let :user do FactoryGirl.create(:user, :manager) end

  describe 'abilities' do
    it_should_behave_like "role abilities", Employee, [:read]
    # it_should_behave_like "role abilities", PermissionRequest, [:manage]
    # it_should_behave_like "role abilities", EquipmentRequest, [:manage]
  end
end
