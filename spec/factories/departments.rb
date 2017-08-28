FactoryGirl.define do
  factory :department do
    sequence(:name)     { |n| Faker::Commerce.department(2) }
    sequence(:code)     { |n| "#{n}12345" }
    sequence(:status)   { |n| "Active"}

    trait :customer_service do
      name { "Customer Support" }
    end
  end
end
