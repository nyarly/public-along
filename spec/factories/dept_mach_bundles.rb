FactoryGirl.define do
  factory :dept_mach_bundle do
    association :department, factory: :department
    association :machine_bundle, factory: :machine_bundle
  end
end
