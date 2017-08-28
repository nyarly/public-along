FactoryGirl.define do
  factory :emp_transaction do
    kind "Security Access"
    association :user, factory: :user
    association :employee, factory: :employee

    factory :onboarding_emp_transaction do
      kind "Onboarding"
    end

    factory :offboarding_emp_transaction do
      kind "Offboarding"
    end
  end
end
