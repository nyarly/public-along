require 'rails_helper'
require 'cancan/matchers'

describe Role::Basic, :type => :model do
  let :user do FactoryGirl.create(:user) end

  describe 'abilities' do
    it_should_behave_like "role abilities", Employee, [:read]
  end
end
