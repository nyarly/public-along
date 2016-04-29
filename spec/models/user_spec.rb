require 'rails_helper'
# TODO - switch to new style expect syntax. 
# Currently, switching this test to new style expect syntax seems to break it.
# Need to debug.
describe User, type: :model do
  subject { FactoryGirl.build(:user) }
  it { should be_valid }

  it { should_not allow_value(nil).for(:first_name) }
  it { should_not allow_value(nil).for(:last_name) }

  it { should_not allow_value(nil).for(:email) }
  it { should validate_uniqueness_of(:email).case_insensitive }

  it { should_not allow_value(nil).for(:ldap_user) }
  it { should validate_uniqueness_of(:ldap_user) }
end
