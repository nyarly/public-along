FactoryGirl.define do
  factory :emp_sec_profile do
    association :emp_transaction, factory: :emp_transaction
    association :security_profile, factory: :security_profile
    revoking_transaction_id nil
  end
end
