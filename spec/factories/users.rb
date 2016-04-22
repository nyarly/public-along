FactoryGirl.define do
  factory :user do
    first_name    { Faker::Name.first_name }
    last_name     { Faker::Name.last_name }
    sequence(:email)     { |n| "#{n}#{Faker::Internet.email}" }
    sequence(:ldap_user) { |n| "#{Faker::Internet.user_name}#{n}" }
  end
end