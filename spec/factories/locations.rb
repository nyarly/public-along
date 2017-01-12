FactoryGirl.define do
  factory :location do
    sequence(:code) { |n| "#{n}OTCODE" }
    name "Location Name"
    status "Active"
    kind "Office"
    country "US"
    timezone "(GMT-08:00) Pacific Time (US & Canada), Tijuana"
  end
end
