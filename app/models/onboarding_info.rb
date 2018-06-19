class OnboardingInfo < ActiveRecord::Base
  validates_inclusion_of :cw_email, in: [true, false]
  validates_inclusion_of :cw_google_membership, in: [true, false]

  belongs_to :emp_transaction, inverse_of: :onboarding_infos
end
