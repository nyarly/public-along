class EmpMachBundle < ActiveRecord::Base
  validates :machine_bundle_id,
            presence: true

  belongs_to :emp_transaction
  belongs_to :machine_bundle
end
