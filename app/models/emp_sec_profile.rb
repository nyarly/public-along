class EmpSecProfile < ActiveRecord::Base
  validates :employee_id,
            presence: true
  validates :security_profile_id,
            presence: true
  attr_accessor :create

  belongs_to :emp_transaction
  belongs_to :employee
  belongs_to :security_profile
end
