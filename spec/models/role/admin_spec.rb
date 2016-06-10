require 'rails_helper'
require 'cancan/matchers'

xdescribe Role::Admin, :type => :model do
  let :user do FactoryGirl.create(:user, :admin) end

  describe 'abilities' do
    subject(:ability) { Ability.new(user) }

    it{ expect(ability).to be_able_to :manage, Department }
    it{ expect(ability).to be_able_to :manage, MachineBundle }
    it{ expect(ability).to be_able_to :manage, OrgRole }
    it{ expect(ability).to be_able_to :manage, OrgApp }
  end
end
