FactoryGirl.define do
  factory :worker_type do
    name "Worker Type Name"
    sequence(:code) { |n| "#{n}WTN" }
    kind "Contingent"
    status "Active"
  end
end
