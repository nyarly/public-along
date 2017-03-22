FactoryGirl.define do
  factory :offboard_command do
    skip_create
    
    employee_id 1

    initialize_with { new(employee_id) }
  end
end
