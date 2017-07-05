FactoryGirl.define do
  factory :access_level do
    name "MyString"
    association :application, factory: :application
    ad_security_group "MyString"
  end
end
