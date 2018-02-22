FactoryGirl.define do
  factory :profile do
    transient do
      employee_args nil
    end
    employee { create(:employee, employee_args) }
    location
    department
    worker_type
    job_title
    start_date      { 1.year.ago }
    end_date        { nil }
    company         { 'OpenTable, Inc.' }
    adp_assoc_oid   { Faker::Number.number(10) }
    adp_employee_id { Faker::Number.number(6) }
    management_position nil

    factory :active_profile do
      profile_status { 'active' }
    end

    factory :leave_profile do
      profile_status { 'leave' }
    end

    factory :terminated_profile do
      profile_status { 'terminated' }
    end

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

    factory :temp do
      association :worker_type, factory: [:worker_type, :temporary]
    end
  end
end

# To pass employee args into profile use this syntax:
# let!(:worker) { FactoryGirl.create(:profile,
#                 start_date: Date.new(2017, 5, 8),
#                 employee_args: {
#                   last_name: "Aaa",
#                   hire_date: Date.new(2017, 5, 8),
#                   request_status: "waiting",
#                   status: "pending" }) }
