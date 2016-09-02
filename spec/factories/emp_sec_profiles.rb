FactoryGirl.define do
  factory :emp_sec_profile do
    emp_transaction_id 1
    association :employee, factory: :employee
    security_profile_id 1
    revoking_transaction_id nil
  end
end
