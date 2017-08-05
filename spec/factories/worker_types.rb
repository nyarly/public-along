FactoryGirl.define do
  factory :worker_type do
    name "Regular Full-Time"
    sequence(:code) { |n| "#{n}WTN" }
    kind "Regular"
    status "Active"
  end

  trait :temporary do
    name { "Temp Fixed Term Full-Time"}
    kind { "Temporary" }
  end

  trait :contractor do
    name { "Agency Contract Worker" }
    kind { "Contractor"}
  end
end
