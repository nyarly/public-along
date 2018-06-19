class ContractorInfo < ActiveRecord::Base
  validates :emp_transaction, presence: true
  belongs_to :emp_transaction, inverse_of: :contractor_infos
end
