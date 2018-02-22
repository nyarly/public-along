FactoryGirl.define do
  factory :currency do
    name 'currency name'
    iso_alpha_code 'AAA'
  end

  trait :usd do
    name 'United States Dollar'
    iso_alpha_code 'USD'
    initialize_with do
      Currency.find_or_create_by(name: name, iso_alpha_code: iso_alpha_code)
    end
  end

  trait :gbp do
    name 'Great British Pound'
    iso_alpha_code 'GBP'
    initialize_with do
      Currency.find_or_create_by(name: name, iso_alpha_code: iso_alpha_code)
    end
  end
end
