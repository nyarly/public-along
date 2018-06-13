require 'rails_helper'
require 'cancan/matchers'

describe Role::Security, type: :model do
  let :user do FactoryGirl.create(:user, :security) end

  describe 'abilities' do
    it_should_behave_like 'role abilities', Employee, [:read, :direct_reports, :autocomplete_name, :autocomplete_email]
    it_should_behave_like 'role abilities', :new_hire, [:read]
    it_should_behave_like 'role abilities', :offboard, [:read]
    it_should_behave_like 'role abilities', :inactive, [:read]
    it_should_behave_like 'role abilities', SecurityProfile, [:read]
    it_should_behave_like 'role abilities', AccessLevel, [:read]
    it_should_behave_like 'role abilities', Application, [:read]
  end
end
