FactoryGirl.define do
  factory :employee do
    first_name            { Faker::Name.first_name }
    last_name             { Faker::Name.last_name }
    workday_username      { (first_name[0,1] + last_name).downcase }
    employee_id           { Faker::Number.number(10) }
    country               { "US" }
    hire_date             { 1.week.from_now}
    job_family_id         { Faker::Number.number(10) }
    job_family            { Faker::Lorem.sentence(3) }
    job_profile_id        { Faker::Number.number(10) }
    job_profile           { Faker::Lorem.sentence(3) }
    business_title        { Faker::Name.title }
    employee_type         { "Regular" }
    location_type         { "Headquarters" }
    location              { "OT San Francisco" }
    manager_id            { Faker::Number.number(10) }
    cost_center           { "OT People & Culture" }
    cost_center_id        { "WP8OT_San_Francisco000011" }
    personal_mobile_phone { Faker::PhoneNumber.phone_number }
    office_phone          { Faker::PhoneNumber.phone_number }
    image_code            { IMAGE }

    trait :contingent do
      employee_id            { nil }
      contingent_worker_id   { Faker::Number.number(10) }
      contingent_worker_type { "Agency" }
      contract_end_date      { 1.month.from_now }
    end

    trait :remote do
      location_type  { "Remote Location" }
      location       { "Remote Location" }
      home_address_1 { Faker::Address.street_address }
      home_city      { Faker::Address.city }
      home_state     { Faker::Address.state_abbr }
      home_zip       { Faker::Address.zip }
    end
  end
end

