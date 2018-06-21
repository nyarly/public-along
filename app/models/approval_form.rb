class ApprovalForm
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :approval
  attr_reader :approver_designation
  attr_reader :emp_transaction
  attr_reader :request_emp_transaction

  attribute :approval_id, Integer
  attribute :approver_designation_id, Integer
  attribute :request_emp_transaction_id, Integer
  attribute :user_id, Integer
  attribute :employee_id, Integer
  attribute :status, String
  attribute :request_action, String
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

  def approver_designation
    approval.approver_designation
  end

  def emp_transaction
    EmpTransaction.new(
      kind: 'approval',
      user_id: user_id,
      employee: request_emp_transaction.employee,
      notes: notes)
  end

  def save
    ActiveRecord::Base.transaction do
      raise  'Request not permitted' if !valid_request_action?
      emp_transaction.save!
      approval.emp_transaction = emp_transaction
      approval.send(state_change)
      approval.save!
    end
  end

  private

  def state_change
    request_action.parameterize.underscore.to_sym
  end

  def valid_request_action?
    permitted_events.include? state_change
  end

  def permitted_events
    approval.aasm.events(permitted: true).map(&:name)
  end

  def persisted?
    true
  end
end
