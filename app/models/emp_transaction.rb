class EmpTransaction < ActiveRecord::Base
  KINDS = ["Security Access", "Equipment"]

  validates :user_id,
            presence: true
  validates :kind,
            presence: true,
            inclusion: { in: KINDS }

  belongs_to :user
  has_many :emp_sec_profiles
  has_many :security_profiles, through: :emp_sec_profiles

  accepts_nested_attributes_for :emp_sec_profiles, :reject_if => proc { |attributes|
    attributes['create'].to_s == "0" || attributes['employee_id'].blank?
  }
end
