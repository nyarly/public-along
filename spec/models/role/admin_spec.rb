require 'rails_helper'
require 'cancan/matchers'

xdescribe Role::Admin, :type => :model do
  let :user do FactoryGirl.create(:user, :admin) end

  describe 'abilities' do
    # it_should_behave_like "role abilities", Department, [:manage]
    # it_should_behave_like "role abilities", MachineBundle, [:manage]
    # it_should_behave_like "role abilities", OrgRole, [:manage]
    # it_should_behave_like "role abilities", OrgApp, [:manage]
  end
end
