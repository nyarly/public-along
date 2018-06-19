FactoryGirl.define do
  factory :emp_transaction do
    kind 'security_access'
    association :user, factory: :user
    association :employee, factory: :employee

    factory :onboarding_emp_transaction do
      kind 'onboarding'
    end

    factory :offboarding_emp_transaction do
      kind 'offboarding'
    end
  end
end
