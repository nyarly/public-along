FactoryGirl.define do
  factory :emp_mach_bundle do
    association :machine_bundle, factory: :machine_bundle
    association :emp_transaction, factory: :emp_transaction
    details ""
  end
end
