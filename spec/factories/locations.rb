FactoryGirl.define do
  factory :location do
    sequence(:code) { |n| "#{n}OTCODE" }
    name { Faker::Address.city }
    status 'Active'
    kind 'Office'
    timezone '(GMT-08:00) Pacific Time (US & Canada), Tijuana'
    association :address, factory: :address
  end

  trait :sf do
    name 'San Francisco Office'
    code 'SF'
    association :address, factory: [:address, :main_office]
    initialize_with { Location.find_or_create_by(code: code) }
  end

  trait :remote do
    kind 'Remote Location'
  end

  trait :eu do
    name 'London Office'
    code 'LON'
    timezone '(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London'
    association :address, factory: [:address, :london_office]
    initialize_with { Location.find_or_create_by(code: code) }
  end

  trait :mex do
    name 'Mexico City Office'
    timezone '(GMT-06:00) Central Time (US & Canada)'
    association :address, factory: [:address, :mexico_office]
  end

  trait :can do
    association :address, factory: [:address, :canadian_address]
  end
end
