class Approval < ActiveRecord::Base
  include AASM

  validates :status, presence: true

  belongs_to :approver_designation, inverse_of: :approvals
  belongs_to :emp_transaction, inverse_of: :approvals
  belongs_to :request_emp_transaction, class_name: 'EmpTransaction', inverse_of: :approval_requests

  aasm column: 'status' do
    state :created, initial: true
    state :requested, before_enter: :set_requested_at
    state :approved, before_enter: :set_approved_at
    state :rejected, before_enter: :set_rejected_at
    state :changes_requested
    state :executed, before_enter: :set_executed_at

    event :request do
      transitions from: :created, to: :requested
    end

    event :approve do
      transitions from: :requested, to: :approved
    end

    event :reject do
      transitions from: :requested, to: :rejected
    end

    event :request_changes do
      transitions from: :requested, to: :changes_requested
    end

    event :execute do
      transitions from: :approved, to: :executed
    end
  end

  def set_approved_at
    self.approved_at = Time.now
  end

  def set_requested_at
    self.requested_at = Time.now
  end

  def set_rejected_at
    self.rejected_at = Time.now
  end

  def set_executed_at
    self.executed_at = Time.now
  end
end
