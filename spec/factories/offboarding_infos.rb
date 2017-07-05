FactoryGirl.define do
  factory :offboarding_info do
    association :employee, factory: :employee
    association :emp_transaction, factory: :emp_transaction
    archive_data true
    replacement_hired true
    forward_email_id { Employee.first.id }
  end
end
