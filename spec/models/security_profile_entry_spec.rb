require 'rails_helper'

RSpec.describe SecurityProfileEntry do
 
 context "Add access level" do
    let(:department) { FactoryGirl.create(:department, id: 555)}
    let(:access_level) { FactoryGirl.create(:access_level, id: 12222, name: "Super Admin")}
    let(:params) do
      {
        name: "Basic Engineering",
        description: "stuff goes here",
        department_ids: [department.id],
        access_level_ids: [access_level.id]
      }
    end

    let(:security_profile_entry) { SecurityProfileEntry.new(params) }

    it "should create a security profile with the right attrs" do
      expect(security_profile_entry.security_profile.name).to eq('Basic Engineering')
      expect(security_profile_entry.security_profile.description).to eq('stuff goes here')
      expect(security_profile_entry.security_profile.department_ids).to eq([555])
      expect(security_profile_entry.security_profile.access_level_ids).to eq([12222])
    end

    it "should create access level infos" do
      expect(security_profile_entry.security_profile.access_levels.first.name).to eq("Super Admin")
    end
  end
  
end