class Approval < ActiveRecord::Base
  include AASM

  validates :status, presence: true

  belongs_to :approver_designation, inverse_of: :approval
  belongs_to :emp_transaction, inverse_of: :approvals
  belongs_to :request_emp_transaction, inverse_of: :approval_requests

  aasm column: 'status' do
    state :created, initial: true
    state :requested
    state :approved
    state :rejected
    state :executed

    event :request do
      transitions from: :created, to: :requested
    end

    event :approve do
      transitions from: :requested, to: :created
    end

    event :reject do
      transitions from: :requested, to: :rejected
    end

    event :execute do
      transitions from: :approved, to: :executed
    end
  end
end
