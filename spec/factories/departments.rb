FactoryGirl.define do
  factory :department do
    sequence(:name)     { |n| "#{n}#{Faker::Commerce.department}" }
    sequence(:code)     { |n| "#{n}12345" }
    sequence(:status)   { |n| "Active"}
  end
end
