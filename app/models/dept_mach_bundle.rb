class DeptMachBundle < ActiveRecord::Base
  validates :department_id,
            presence: true
  validates :machine_bundle_id,
            presence: true

  belongs_to :department
  belongs_to :machine_bundle
end
