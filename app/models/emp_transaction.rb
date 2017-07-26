class EmpTransaction < ActiveRecord::Base
  KINDS = ["Security Access", "Equipment", "Onboarding", "Offboarding"]

  validates :user_id,
            presence: true
  validates :kind,
            presence: true,
            inclusion: { in: KINDS }

  belongs_to :user
  has_many :emp_sec_profiles, :foreign_key => "emp_transaction_id"
  has_many :security_profiles, through: :emp_sec_profiles
  has_many :emp_mach_bundles
  has_many :machine_bundles, through: :emp_mach_bundles
  has_many :revoked_emp_sec_profiles, class_name: "EmpSecProfile", inverse_of: :revoking_transaction, :foreign_key => "revoking_transaction_id"
  has_many :revoked_security_profiles, through: :revoked_emp_sec_profiles, source: :security_profile
  has_many :onboarding_infos
  has_many :offboarding_infos
end
