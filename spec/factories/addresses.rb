FactoryGirl.define do
  factory :address do
    line_1          { Faker::Address.street_address }
    line_2          { Faker::Address.secondary_address }
    city            { Faker::Address.city }
    state_territory { Faker::Address.state }
    postal_code     { Faker::Address.zip }
    association     :country, factory: [:country, :us]
  end

  trait :london_office do
    association :country, :factory => [:country, :gb]
  end
end
