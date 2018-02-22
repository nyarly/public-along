FactoryGirl.define do
  factory :country do
    name                            { Faker::Address.country }
    sequence(:iso_alpha_2_code)     { |n| "#{n}12345" }
    association                     :currency, factory: :currency
  end

  trait :gb do
    name 'Great Britain'
    iso_alpha_2_code 'GB'
    initialize_with { Country.find_or_create_by(name: name, iso_alpha_2_code: iso_alpha_2_code) }
    association :currency, factory: [:currency, :gbp]
  end

  trait :us do
    name 'United States'
    iso_alpha_2_code 'US'
    initialize_with { Country.find_or_create_by(name: name, iso_alpha_2_code: iso_alpha_2_code) }
    association :currency, factory: [:currency, :usd]
  end

  trait :mx do
    name 'Mexico'
    iso_alpha_2_code 'MX'
    initialize_with { Country.find_or_create_by(name: name, iso_alpha_2_code: iso_alpha_2_code) }
  end

  trait :ca do
    name 'Canada'
    iso_alpha_2_code 'CA'
    initialize_with { Country.find_or_create_by(name: name, iso_alpha_2_code: iso_alpha_2_code) }
  end
end
