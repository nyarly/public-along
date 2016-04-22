require 'rails_helper'

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
