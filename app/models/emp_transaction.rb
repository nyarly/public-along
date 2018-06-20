class EmpTransaction < ActiveRecord::Base
  extend Tokenable

  FORMS = {
    'approval' => '',
    'job_change' => JobChangeForm,
    'new_contractor' => NewContractorForm,
    'offboarding' => OffboardingForm,
    'onboarding' => OnboardingForm,
    'security_access' => SecurityAccessForm,
    'service' => ''
  }.freeze

  validates :kind, presence: true, inclusion: { in: FORMS.keys }
  validates :employee, presence: true

  has_many :approvals, inverse_of: :emp_transaction, foreign_key: 'emp_transaction_id'
  has_many :approval_requests, class_name: 'Approval', inverse_of: :request_emp_transaction, foreign_key: 'request_emp_transaction_id'
  belongs_to :user
  belongs_to :employee
  has_many :emp_sec_profiles
  has_many :security_profiles, through: :emp_sec_profiles
  has_many :emp_mach_bundles
  has_many :machine_bundles, through: :emp_mach_bundles
  has_many :revoked_emp_sec_profiles, class_name: 'EmpSecProfile', inverse_of: :revoking_transaction, :foreign_key => "revoking_transaction_id"
  has_many :revoked_security_profiles, through: :revoked_emp_sec_profiles, source: :security_profile
  has_many :onboarding_infos, inverse_of: :emp_transaction
  has_many :offboarding_infos, inverse_of: :emp_transaction
  has_many :contractor_infos, inverse_of: :emp_transaction

  accepts_nested_attributes_for :onboarding_infos
  accepts_nested_attributes_for :offboarding_infos
  accepts_nested_attributes_for :contractor_infos

  FORMS.keys.each do |transaction_type|
    method_name = transaction_type + "?"
    define_method method_name.to_sym do
      transaction_type == kind
    end
  end

  def self.token
    generate_token
  end

  def performed_by
    return 'Mezzo' if service?
    self.user.try(:full_name)
  end

  def process!
    TransactionProcesser.new(self).call
  end
end
