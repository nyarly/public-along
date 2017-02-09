FactoryGirl.define do
  factory :parent_org do
    sequence(:name) { |n| "#{n}#{Faker::Commerce.department}" }
    sequence(:code) { |n| "#{n}OTCODE" }
  end
end
