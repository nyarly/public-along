class EmpSecProfile < ActiveRecord::Base
  validates :transaction_id,
            presence: true
  validates :employee_id,
            presence: true
  validates :security_profile_id,
            presence: true
end
