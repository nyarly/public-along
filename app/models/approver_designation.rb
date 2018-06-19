class ApproverDesignation < ActiveRecord::Base
  KINDS = ['HRBP', 'TechTable', 'Manager']

  validates :active, presence: true
  validates :kind, presence: true, inclusion: { in: KINDS }

  belongs_to :department, inverse_of: :approver_designations
  belongs_to :employee
  belongs_to :location, inverse_of: :approver_designations
end
