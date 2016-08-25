class EmpMachBundle < ActiveRecord::Base
  validates :employee_id,
            presence: true
  validates :machine_bundle_id,
            presence: true

  belongs_to :emp_transaction
  belongs_to :employee
  belongs_to :machine_bundle
end
