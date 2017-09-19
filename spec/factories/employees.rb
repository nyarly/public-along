FactoryGirl.define do
  factory :employee do
    first_name            { Faker::Name.first_name }
    last_name             { Faker::Name.last_name }
    hire_date             { 1.year.ago }
    personal_mobile_phone { Faker::PhoneNumber.phone_number }
    office_phone          { Faker::PhoneNumber.phone_number }
    image_code            { IMAGE }

    trait :existing do
      created_at    { 2.months.ago }
      updated_at    { 1.month.ago }
      ad_updated_at { 1.month.ago }
    end

    factory :regular_employee do
      transient do
        profiles_count 1
      end

      after(:create) do |employee, evaluator|
        create_list(:profile, evaluator.profiles_count, employee: employee)
      end
    end

    factory :remote_employee do
      home_address_1 { Faker::Address.street_address }
      home_city      { Faker::Address.city }
      home_state     { Faker::Address.state_abbr }
      home_zip       { Faker::Address.zip }
      transient do
        profiles_count 1
      end

      after(:create) do |employee, evaluator|
        create_list(:remote_ftr, evaluator.profiles_count, employee: employee)
      end
    end

    factory :contract_worker do
      contract_end_date { 1.month.from_now }
      transient do
        profiles_count 1
      end

      after(:create) do |employee, evaluator|
        create_list(:contractor, evaluator.profiles_count, employee: employee)
      end
    end
  end
end

