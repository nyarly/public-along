FactoryGirl.define do
  factory :sec_prof_access_level do
    association :security_profile, factory: :security_profile
    association :access_level, factory: :access_level
  end
end
