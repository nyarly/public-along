FactoryGirl.define do
  factory :country do
    name                    { Faker::Address.country }
    sequence(:iso_alpha_2)  { |n| "#{n}1" }
    sequence(:iso_alpha_3)  { |n| "#{n}12" }
    association             :currency, factory: :currency
  end

  trait :gb do
    name 'Great Britain'
    iso_alpha_2 'GB'
    initialize_with { Country.find_or_create_by(name: name, iso_alpha_2: iso_alpha_2) }
    association :currency, factory: [:currency, :gbp]
  end

  trait :us do
    name 'United States'
    iso_alpha_2 'US'
    initialize_with { Country.find_or_create_by(name: name, iso_alpha_2: iso_alpha_2) }
    association :currency, factory: [:currency, :usd]
  end

  trait :mx do
    name 'Mexico'
    iso_alpha_2 'MX'
    initialize_with { Country.find_or_create_by(name: name, iso_alpha_2: iso_alpha_2) }
  end

  trait :ca do
    name 'Canada'
    iso_alpha_2 'CA'
    initialize_with { Country.find_or_create_by(name: name, iso_alpha_2: iso_alpha_2) }
  end
end
