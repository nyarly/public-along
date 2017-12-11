require 'rails_helper'
require 'cancan/matchers'

describe Role::Security, type: :model do
  let :user do FactoryGirl.create(:user, :security) end

  describe 'abilities' do
    it_should_behave_like 'role abilities', Employee, [:read, :direct_reports, :autocomplete_name]
    it_should_behave_like 'role abilities', Profile, [:read]
  end
end
