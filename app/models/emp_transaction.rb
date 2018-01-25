class EmpTransaction < ActiveRecord::Base
  include Tokenable
  attr_accessor :token

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

  KINDS.each do |transaction_type|
    method_name = transaction_type.gsub(" ","_").downcase + "?"
    define_method method_name.to_sym do
      transaction_type == kind
    end
  end

  def token
    @token ||= generate_token
  end

  def performed_by
    return "Mezzo" if service?
    self.user.try(:full_name)
  end

  def process!
    TransactionProcesser.new(self).call
  end
end
