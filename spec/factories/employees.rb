FactoryGirl.define do
  factory :employee do
    first_name            { Faker::Name.first_name }
    last_name             { Faker::Name.last_name }
    workday_username      { (first_name[0,1] + last_name).downcase }
    employee_id           { Faker::Number.number(10) }
    hire_date             { 1.week.from_now}
    job_family_id         { Faker::Number.number(10) }
    job_family            { Faker::Lorem.sentence(3) }
    job_profile_id        { Faker::Number.number(10) }
    job_profile           { Faker::Lorem.sentence(3) }
    business_title        { Faker::Name.title }
    employee_type         { "Regular" }
    manager_id            { Faker::Number.number(10) }
    department_id         { Department.all.map(&:id).sample || 1 }
    personal_mobile_phone { Faker::PhoneNumber.phone_number }
    office_phone          { Faker::PhoneNumber.phone_number }
    image_code            { IMAGE }
    location_id           { Location.all.map(&:id).sample || 1 }

    trait :contingent do
      employee_id            { nil }
      employee_type          { "Agency Contractor" }
      contingent_worker_id   { Faker::Number.number(10) }
      contingent_worker_type { "Agency Contractor" }
      contract_end_date      { 1.month.from_now }
    end

    trait :remote do
      # location_type  { "Remote Location" }
      # location       { "Remote Location" }
      home_address_1 { Faker::Address.street_address }
      home_city      { Faker::Address.city }
      home_state     { Faker::Address.state_abbr }
      home_zip       { Faker::Address.zip }
    end

    trait :existing do
      created_at    { 2.months.ago }
      updated_at    { 1.month.ago }
      ad_updated_at { 1.month.ago }
    end
  end
end

