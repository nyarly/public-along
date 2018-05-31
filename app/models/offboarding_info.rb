class OffboardingInfo < ActiveRecord::Base
  validates :forward_email_id,
            presence: true
  validates :reassign_salesforce_id,
            presence: true
  validates_inclusion_of :archive_data, in: [true, false]
  validates_inclusion_of :replacement_hired, in: [true, false]

  belongs_to :emp_transaction, inverse_of: :offboarding_infos
end
