FactoryGirl.define do
  factory :emp_access_level do
    association :employee, factory: :employee
    association :access_level, factory: :access_level
    active true
  end
end
