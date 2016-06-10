require 'rails_helper'
require 'cancan/matchers'

xdescribe Role::Helpdesk, :type => :model do
  let :user do FactoryGirl.create(:user, :helpdesk) end

  describe 'abilities' do
    subject(:ability) { Ability.new(user) }

    it{ expect(ability).to be_able_to :manage, PermissionRequest }
    it{ expect(ability).to be_able_to :manage, EquipmentRequest }
  end
end
