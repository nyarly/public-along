FactoryGirl.define do
  factory :emp_sec_profile do
    emp_transaction_id 1
    association :employee, factory: :employee
    security_profile_id 1
    revoke_date nil
  end
end
