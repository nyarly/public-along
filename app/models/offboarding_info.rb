class OffboardingInfo < ActiveRecord::Base
  validates :employee_id,
            presence: true
  validates :forward_email_id,
            presence: true
  validates :reassign_salesforce_id,
            presence: true

  belongs_to :emp_transaction
  belongs_to :employee
end
