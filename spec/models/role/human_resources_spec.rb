require 'rails_helper'
require 'cancan/matchers'

describe Role::HumanResources, :type => :model do
  let :user do FactoryGirl.create(:user, :human_resources) end

  describe 'abilities' do
    it_should_behave_like "role abilities", Employee, [:read, :create, :update]
  end
end
