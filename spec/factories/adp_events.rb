FactoryGirl.define do
  factory :adp_event do
    json "MyText"
    status "New"
    sequence(:msg_id) { |n| "somemessageidfromadp#{n}"}
  end
end
