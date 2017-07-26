FactoryGirl.define do
  factory :offboarding_info do
    association :emp_transaction, factory: :emp_transaction
    archive_data true
    replacement_hired true
    forward_email_id { Employee.first.id }
    reassign_salesforce_id { Employee.first.id }
  end
end
