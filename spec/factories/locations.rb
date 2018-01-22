FactoryGirl.define do
  factory :location do
    sequence(:code) { |n| "#{n}OTCODE" }
    name { Faker::Address.city }
    status "Active"
    kind "Office"
    timezone "(GMT-08:00) Pacific Time (US & Canada), Tijuana"
    association :address, factory: :address
  end

  trait :remote do
    kind "Remote Location"
  end

  trait :eu do
    name "London Office"
    timezone "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"
    association :address, :factory => [:address, :london_office]
  end
end
