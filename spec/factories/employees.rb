FactoryGirl.define do
  factory :employee do
    first_name            { Faker::Name.first_name }
    last_name             { Faker::Name.last_name }
    # employee_id           { Faker::Number.number(10) }
    hire_date             { 1.year.ago }
    # business_title        { Faker::Name.title }
    # manager_id            { Faker::Number.number(10) }
    personal_mobile_phone { Faker::PhoneNumber.phone_number }
    office_phone          { Faker::PhoneNumber.phone_number }
    image_code            { IMAGE }
    status                { "Active" }
    # association :department, factory: :department
    # association :job_title, factory: :job_title
    # association :worker_type, factory: :worker_type
    # association :location, factory: :location

    # trait :contingent do
    #   email { nil }
    #   contract_end_date { 1.month.from_now }
    #   # association :worker_type, :factory => [:worker_type, :contractor]
    # end

    # trait :remote do
    #   # association :location, :factory => [:location, :remote]
    #   home_address_1 { Faker::Address.street_address }
    #   home_city      { Faker::Address.city }
    #   home_state     { Faker::Address.state_abbr }
    #   home_zip       { Faker::Address.zip }
    # end

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
  # factory :remote_employee, :parent => :employee do |e|
  #   e.build(:profile, :factory => [:profile, :remote_ftr])
  # # end
  # factory :regular_employee, :parent => :employee do |e|
  #   e.build(:profile)
  # end

  # factory :contract_employee, :parent => :employee do |e|
  #   e.build(:profile, :factory => [:profile, :contractor ])
  # end
end

