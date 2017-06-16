FactoryGirl.define do
  factory :application do
    name "MyString"
    description "MyText"
    dependency "MyText"
    ad_controls true
    onboard_instructions "MyText"
    offboard_instructions "MyText"
  end
end
