FactoryGirl.define do
  factory :profile do
    association :employee, factory: :employee
    association :department, factory: :department
    association :location, factory: :location
    association :worker_type, factory: :worker_type
    association :job_title, factory: :job_title
    status          { "Active" }
    start_date      { 1.year.ago }
    end_date        { nil }
    company         { "OpenTable, Inc." }
    adp_assoc_oid   { "AABBCCDD" }
    adp_employee_id { Faker::Number.number(10) }

  end
end
