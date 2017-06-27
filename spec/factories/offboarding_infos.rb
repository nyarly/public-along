FactoryGirl.define do
  factory :offboarding_info do
    association :employee, factory: :employee
    association :emp_transaction, factory: :emp_transaction
    archive_data false
    replacement_hired false
    forward_email_id 1
    reassign_salesforce_id 1
    transfer_google_docs_id 1
  end
end
