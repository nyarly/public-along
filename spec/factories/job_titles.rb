FactoryGirl.define do
  factory :job_title do
    name            { Faker::Name.title }
    sequence(:code) { |n| "#{n}12345" }
    status "Active"
  end
end
