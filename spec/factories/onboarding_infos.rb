FactoryGirl.define do
  factory :onboarding_info do
    association :employee, factory: :employee
    association :emp_transcation, factory: :emp_transaction
    association :buddy_id, factory: :employee
    cw_email false
    cw_google_membership false
  end
end
