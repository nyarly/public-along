class OffboardingInfo < ActiveRecord::Base
  validates :employee_id,
            presence: true


  belongs_to :emp_transaction
  belongs_to :employee
end
