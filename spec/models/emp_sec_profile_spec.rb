require 'rails_helper'

RSpec.describe EmpSecProfile, type: :model do
  let!(:employee)         { FactoryGirl.create(:employee) }
  let!(:security_profile) { FactoryGirl.create(:security_profile) }
  let!(:emp_transaction)  { FactoryGirl.create(:emp_transaction,
                                            kind: "Onboarding",
                                            employee_id: employee.id) }
  let!(:emp_sec_profile)  { FactoryGirl.create(:emp_sec_profile,
                                            security_profile_id: security_profile.id,
                                            emp_transaction_id: emp_transaction.id) }

  it "should meet validations" do
    expect(emp_sec_profile).to be_valid
    expect(emp_sec_profile).to_not allow_value(nil).for(:security_profile_id)
  end

  context "should allow dup sec profile if older esps have a revoke date" do
    let!(:employee)        { FactoryGirl.create(:employee, first_name: "bablablblab") }
    let!(:security_prof_2) { FactoryGirl.create(:security_profile) }
    let!(:emp_transaction) { FactoryGirl.create(:emp_transaction,
                                               kind: "Service",
                                               employee_id: employee.id) }
    let(:esp)             { FactoryGirl.create(:emp_sec_profile,
                                               revoking_transaction_id: nil,
                                               security_profile_id: security_prof_2.id,
                                               emp_transaction_id: emp_transaction.id) }
    let!(:emp_trans_2)     { FactoryGirl.create(:emp_transaction,
                                               kind: "Onboarding",
                                               employee_id: employee.id)}
    let(:esp_2)           { FactoryGirl.build(:emp_sec_profile,
                                              emp_transaction_id: emp_trans_2.id,
                                              revoking_transaction_id: nil,
                                              security_profile_id: security_prof_2.id) }
    let(:esp_3)           { FactoryGirl.build(:emp_sec_profile,
                                              emp_transaction_id: emp_trans_2.id,
                                              revoking_transaction_id: nil,
                                              security_profile_id: security_prof_2.id) }
    let(:revoking_transaction) { FactoryGirl.create(:emp_transaction,
                                               employee_id: employee.id,
                                               kind: "Security Access")}

    it "should reject a dup esp if the older one does not have a revoke date" do
      expect(esp).to be_valid
      expect(esp_2).to_not be_valid
      expect(esp_2.errors.messages).to eq({:security_profile_id=>["can't have duplicate security profiles for one employee"]})
    end

    it "should allow a dup esp if the older one has a revoke date" do
      esp.revoking_transaction_id = revoking_transaction.id
      esp.save!
      esp.reload

      expect(esp).to be_valid
      expect(esp_2).to be_valid
    end

    it "should reject a dup esp with multiple records with any nil revoke dates" do
      esp.revoking_transaction_id = revoking_transaction.id
      esp.save!
      esp.reload
      expect(esp).to be_valid

      esp_2.revoking_transaction_id = nil
      esp_2.save!
      esp_2.reload
      expect(esp_2).to be_valid

      expect(esp_3).to_not be_valid
      expect(esp_3.errors.messages).to eq({:security_profile_id=>["can't have duplicate security profiles for one employee"]})
    end

    it "should allow a dup esp with multiple records with revoke dates" do
      esp.revoking_transaction_id = revoking_transaction.id
      esp.save!
      esp.reload

      esp_2.revoking_transaction_id = revoking_transaction.id
      esp_2.save!
      esp_2.reload

      expect(esp).to be_valid
      expect(esp_2).to be_valid
      expect(esp_3).to be_valid
    end
  end
end
