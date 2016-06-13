FactoryGirl.define do
  factory :user do
    first_name           { Faker::Name.first_name }
    last_name            { Faker::Name.last_name }
    sequence(:email)     { |n| "#{n}#{Faker::Internet.email}" }
    sequence(:ldap_user) { |n| "#{Faker::Internet.user_name}#{n}" }
    role_name            { "Basic" }
  end

  trait :admin do
    role_name { "Admin" }
  end

  trait :helpdesk do
    role_name { "Helpdesk" }
  end

  trait :human_resources do
    role_name { "HumanResources" }
  end

  trait :manager do
    role_name { "Manager" }
  end
end
