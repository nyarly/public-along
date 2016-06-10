require 'rails_helper'
require 'cancan/matchers'

describe Role::HumanResources, :type => :model do
  let :user do FactoryGirl.create(:user, :human_resources) end

  describe 'abilities' do
    subject(:ability) { Ability.new(user) }

    it{ expect(ability).to be_able_to :read, Employee }
    it{ expect(ability).to_not be_able_to :manage, Employee }
  end
end
