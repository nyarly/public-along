FactoryGirl.define do
  factory :contractor_info do
    association :emp_transaction, factory: :emp_transaction
    sequence(:req_or_po_number) { |n| "#{n}otreq" }
    legal_approver { Faker::Name.name }
  end
end
