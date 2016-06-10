require 'rails_helper'
require 'cancan/matchers'

describe Role::Manager, :type => :model do
  let :user do FactoryGirl.create(:user, :manager) end

  describe 'abilities' do
    subject(:ability) { Ability.new(user) }

    it{ expect(ability).to be_able_to :read, Employee }
    it{ expect(ability).to_not be_able_to :manage, Employee }
    xit{ expect(ability).to be_able_to :manage, PermissionRequest }
    xit{ expect(ability).to be_able_to :manage, EquipmentRequest }
  end
end
