class Email
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attribute :email_option, String
  attribute :employee_id, String

  validates :email_option, :employee_id, presence: true

  attr_accessor :employee_id, :email_option

  def persisted?
    false
  end
end
