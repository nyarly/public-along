FactoryGirl.define do
  factory :parent_org do
    name "Parent Org Name"
    sequence(:code) { |n| "#{n}OTCODE" }
  end
end
