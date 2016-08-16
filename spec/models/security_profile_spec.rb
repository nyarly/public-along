require 'rails_helper'

RSpec.describe SecurityProfile, type: :model do
  let(:security_profile) { FactoryGirl.build(:security_profile) }

  it "should meet validations" do
    expect(security_profile).to be_valid

    expect(security_profile).to_not allow_value(nil).for(:name)
  end

  it "should scope on department" do
    security_profile_1 = FactoryGirl.create(:security_profile)
    security_profile_2 = FactoryGirl.create(:security_profile)
    security_profile_3 = FactoryGirl.create(:security_profile)
    department_1 = FactoryGirl.create(:department)
    department_2 = FactoryGirl.create(:department)
    dept_sec_prof_1 = FactoryGirl.create(:dept_sec_prof, department_id: department_1.id, security_profile_id: security_profile_1.id)
    dept_sec_prof_2 = FactoryGirl.create(:dept_sec_prof, department_id: department_2.id, security_profile_id: security_profile_2.id)

    expect(SecurityProfile.find_profiles_for(department_1.id)).to     include(security_profile_1)
    expect(SecurityProfile.find_profiles_for(department_1.id)).to_not include(security_profile_2)
    expect(SecurityProfile.find_profiles_for(department_1.id)).to_not include(security_profile_3)
  end
end
