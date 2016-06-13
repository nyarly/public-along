require 'rails_helper'
require 'cancan/matchers'

xdescribe Role::Helpdesk, :type => :model do
  let :user do FactoryGirl.create(:user, :helpdesk) end

  describe 'abilities' do
    # it_should_behave_like "role abilities", PermissionRequest, [:manage]
    # it_should_behave_like "role abilities", EquipmentRequest, [:manage]
  end
end
