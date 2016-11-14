FactoryGirl.define do
  factory :location do
    sequence(:name) { |n| "#{n} OT HQ" }
    kind "Office"
    country "US"
  end
end
