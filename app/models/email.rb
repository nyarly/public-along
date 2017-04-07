class Email
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attribute :email_kind, String
  attribute :employee_id, String

  validates :email_kind, :employee_id, presence: true

  attr_accessor :employee_id, :email_kind

  def persisted?
    false
  end

end