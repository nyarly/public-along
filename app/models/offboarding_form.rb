class OffboardingForm
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :emp_transaction
  attr_accessor :employee

  attribute :archive_data, Boolean
  attribute :replacement_hired, Boolean
  attribute :forward_email_id, Integer
  attribute :reassign_salesforce_id, Integer
  attribute :transfer_google_docs_id, Integer

  def initialize(params)
    params.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def offboarding_info
    emp_transaction.offboarding_infos.build(
      archive_data: archive_data,
      replacement_hired: replacement_hired,
      forward_email_id: forward_email_id,
      reassign_salesforce_id: reassign_salesforce_id,
      transfer_google_docs_id: transfer_google_docs_id
    )
  end

  def save
    offboarding_info.save!
    employee.complete!
  end
end
