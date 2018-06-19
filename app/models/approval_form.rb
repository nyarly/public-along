class ApprovalForm
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :approval
  attr_accessor :approver_designation
  attr_accessor :emp_transaction
  attr_accessor :request_emp_transaction

  attribute :approval_id, Integer
  attribute :approver_designation_id, Integer
  attribute :request_emp_transaction_id, Integer
  attribute :user_id, Integer
  attribute :employee_id, Integer
  attribute :status, String
  attribute :decision, String
  attribute :notes, String

  def initialize(params)
    params.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def approval
    @approval ||= Approval.find(approval_id)
  end

  def request_emp_transaction
    approval.request_emp_transaction
  end

  def save
    byebug
  end
end
