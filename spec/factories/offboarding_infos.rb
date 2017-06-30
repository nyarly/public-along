FactoryGirl.define do
  factory :offboarding_info do
    association :employee, factory: :employee
    association :emp_transaction, factory: :emp_transaction
    archive_data false
    replacement_hired false
  end
end
