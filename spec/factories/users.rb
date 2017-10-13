FactoryGirl.define do
  factory :user do
    first_name                 { Faker::Name.first_name }
    last_name                  { Faker::Name.last_name }
    sequence(:email)           { |n| "#{n}#{Faker::Internet.email}" }
    sequence(:ldap_user)       { |n| "#{Faker::Internet.user_name}#{n}" }
    role_names                 { ["Manager"] }
    sequence(:adp_employee_id) { |n| "23712ghjk#{n}" }
  end

  trait :admin do
    role_names { ["Admin"] }
  end

  trait :helpdesk do
    role_names { ["Helpdesk"] }
  end

  trait :human_resources do
    role_names { ["HumanResources"] }
  end

  trait :manager do
    role_names { ["Manager"] }
  end
end
