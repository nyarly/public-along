FactoryGirl.define do
  factory :emp_transaction do
    kind "Security Access"
    association :user, factory: :user
  end
end
