class ApproverDesignation < ActiveRecord::Base
  KINDS = ['HRBP', 'TechTable', 'Manager']

  validates :kind, presence: true, inclusion: { in: KINDS }

  has_many :approvals, inverse_of: :approver_designation
  belongs_to :department, inverse_of: :approver_designations
  belongs_to :employee
  belongs_to :location, inverse_of: :approver_designations
end
