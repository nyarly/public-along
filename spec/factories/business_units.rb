FactoryGirl.define do
  factory :business_unit do
    name            { Faker::Company.name }
    sequence(:code) { |n| "#{n}12345" }
    active 't'
  end
end
