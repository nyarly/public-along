FactoryGirl.define do
  factory :dept_sec_prof do
    association :department, factory: :department
    association :security_profile, factory: :security_profile
  end
end
