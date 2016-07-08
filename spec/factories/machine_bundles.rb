FactoryGirl.define do
  factory :machine_bundle do
    sequence(:name)     { |n| "Machine Bundle ##{n}" }
    description "MyText"
  end
end
