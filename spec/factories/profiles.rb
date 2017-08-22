FactoryGirl.define do
  factory :profile do
    association :employee, factory: :employee
    association :department, factory: :department
    association :location, factory: :location
    association :worker_type, factory: :worker_type
    association :job_title, factory: :job_title
    profile_status          { "Active" }
    start_date      { 1.year.ago }
    end_date        { nil }
    company         { "OpenTable, Inc." }
    adp_assoc_oid   { Faker::Number.number(10) }
    adp_employee_id { Faker::Number.number(6) }

    trait :with_valid_ou do
      association :location, :factory => [:location, :eu]
      association :department, :factory => [:department, :customer_service]
    end


    trait :remote do
      association :location, :factory => [:location, :remote]
    end

    factory :remote_ftr do
      association :location, :factory => [:location, :remote]
    end

    factory :contractor do
      association :worker_type, :factory => [:worker_type, :contractor]
    end
  end
end
