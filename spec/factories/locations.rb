FactoryGirl.define do
  factory :location do
    sequence(:code) { |n| "#{n}OTCODE" }
    name { Faker::Address.city }
    status "Active"
    kind "Office"
    country "US"
    timezone "(GMT-08:00) Pacific Time (US & Canada), Tijuana"
  end

  trait :remote do
    kind "Remote Location"
  end

  trait :eu do
    name "London Office"
    country "GB"
    timezone "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"
  end
end
