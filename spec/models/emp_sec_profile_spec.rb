require 'rails_helper'

RSpec.describe EmpSecProfile, type: :model do
  let(:emp_sec_profile) { FactoryGirl.build(:emp_sec_profile, security_profile_id: security_profile.id, employee_id: employee.id) }
  let(:security_profile) { FactoryGirl.create(:security_profile) }
  let(:employee) { FactoryGirl.create(:employee, id: 23) }
  let(:user) { FactoryGirl.create(:user) }
  let(:revoking_transaction) { FactoryGirl.create(:emp_transaction, kind: "Security Access", user_id: user.id)}

  it "should meet validations" do
    expect(emp_sec_profile).to be_valid

    expect(emp_sec_profile).to_not allow_value(nil).for(:employee_id)
    expect(emp_sec_profile).to_not allow_value(nil).for(:security_profile_id)
  end

  context "should allow dup sec profile if older esps have a revoke date" do
    let!(:esp_1) { FactoryGirl.create(:emp_sec_profile, revoking_transaction_id: nil, security_profile_id: sec_profile.id, employee_id: emp.id) }
    let!(:esp_2) { FactoryGirl.build(:emp_sec_profile, revoking_transaction_id: nil, security_profile_id: sec_profile.id, employee_id: emp.id) }
    let!(:esp_3) { FactoryGirl.build(:emp_sec_profile, revoking_transaction_id: nil, security_profile_id: sec_profile.id, employee_id: emp.id) }
    let(:sec_profile) { FactoryGirl.create(:security_profile) }
    let(:emp) { FactoryGirl.create(:employee, id: 23) }

    it "should reject a dup esp if the older one does not have a revoke date" do
      expect(esp_1).to be_valid
      expect(esp_2).to_not be_valid
      expect(esp_2.errors.messages).to eq({:security_profile_id=>["can't have duplicate security profiles for one employee"]})
    end

    it "should allow a dup esp if the older one has a revoke date" do
      esp_1.revoking_transaction_id = revoking_transaction.id
      esp_1.save!
      esp_1.reload

      expect(esp_1).to be_valid
      expect(esp_2).to be_valid
    end

    it "should reject a dup esp with multiple records with any nil revoke dates" do
      esp_1.revoking_transaction_id = revoking_transaction.id
      esp_1.save!
      esp_1.reload
      expect(esp_1).to be_valid

      esp_2.revoking_transaction_id = nil
      esp_2.save!
      esp_2.reload
      expect(esp_2).to be_valid

      expect(esp_3).to_not be_valid
      expect(esp_3.errors.messages).to eq({:security_profile_id=>["can't have duplicate security profiles for one employee"]})
    end

    it "should allow a dup esp with multiple records with revoke dates" do
      esp_1.revoking_transaction_id = revoking_transaction.id
      esp_1.save!
      esp_1.reload

      esp_2.revoking_transaction_id = revoking_transaction.id
      esp_2.save!
      esp_2.reload

      expect(esp_1).to be_valid
      expect(esp_2).to be_valid
      expect(esp_3).to be_valid
    end
  end
end
