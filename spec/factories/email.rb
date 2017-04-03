FactoryGirl.define do
  factory :email do
    skip_create
    
    employee_id 1
    email_kind "Offboarding"

  end
end
