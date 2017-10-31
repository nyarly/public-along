class EmpTransaction < ActiveRecord::Base
  KINDS = ["Security Access", "Equipment", "Onboarding", "Offboarding", "Service"]

  validates :kind,
            presence: true,
            inclusion: { in: KINDS }

  belongs_to :user
  belongs_to :employee
  has_many :emp_sec_profiles
  has_many :security_profiles, through: :emp_sec_profiles
  has_many :emp_mach_bundles
  has_many :machine_bundles, through: :emp_mach_bundles
  has_many :revoked_emp_sec_profiles, class_name: "EmpSecProfile", inverse_of: :revoking_transaction, :foreign_key => "revoking_transaction_id"
  has_many :revoked_security_profiles, through: :revoked_emp_sec_profiles, source: :security_profile
  has_many :onboarding_infos
  has_many :offboarding_infos

  def performed_by
    return "Mezzo" if kind == "Service"
    self.user.try(:full_name)
  end
end
