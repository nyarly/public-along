FactoryGirl.define do
  factory :emp_delta, class: 'EmpDelta' do
    association :employee, factory: :employee
    before ""
    after ""
  end
end
