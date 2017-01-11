FactoryGirl.define do
  factory :location do
    sequence(:code) { |n| "#{n}OTCODE" }
    name "Location Name"
    status "Active"
    kind "Office"
    country "US"
  end
end
