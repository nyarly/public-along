class OnboardingForm
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :emp_transaction
  attr_accessor :employee

  attribute :buddy_id, Integer
  attribute :cw_email, Boolean
  attribute :cw_google_membership, Boolean

  def initialize(params)
    params.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def onboarding_info
    emp_transaction.onboarding_infos.build(
      buddy_id: buddy_id,
      cw_email: cw_email,
      cw_google_membership: cw_google_membership
    )
  end

  def save
    employee.complete!
    onboarding_info.save!
  end
end
