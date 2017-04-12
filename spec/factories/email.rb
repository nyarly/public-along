FactoryGirl.define do
  factory :email do
    skip_create
    
    employee_id 1
    email_option "Offboarding"

  end
end
