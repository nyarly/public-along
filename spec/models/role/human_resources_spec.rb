require 'rails_helper'
require 'cancan/matchers'

describe Role::HumanResources, :type => :model do
  let :user do FactoryGirl.create(:user, :human_resources) end

  describe 'abilities' do
    it_should_behave_like "role abilities", Employee, [:read, :autocomplete_name]
    it_should_behave_like "role abilities", Department, [:manage]
    it_should_behave_like "role abilities", Location, [:manage]
    it_should_behave_like "role abilities", ParentOrg, [:manage]
    it_should_behave_like "role abilities", WorkerType, [:manage]
    it_should_behave_like "role abilities", Email, [:create]
    it_should_behave_like "role abilities", :new_hire, [:read]
    it_should_behave_like "role abilities", :offboard, [:read]
    it_should_behave_like "role abilities", :inactive, [:read]
  end
end
