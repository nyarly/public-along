require 'rails_helper'
# TODO - switch to new style expect syntax.
# Currently, switching this test to new style expect syntax seems to break it.
# Need to debug.
describe User, type: :model do
  let!(:user) { FactoryGirl.build(:user) }
  it "should have validations" do
    expect(user).to be_valid

    expect(user).to_not allow_value(nil).for(:first_name)
    expect(user).to_not allow_value(nil).for(:last_name)

    expect(user).to_not allow_value(nil).for(:email)
    should validate_uniqueness_of(:email).case_insensitive

    expect(user).to_not allow_value(nil).for(:ldap_user)
    should validate_uniqueness_of(:ldap_user)
  end
end
