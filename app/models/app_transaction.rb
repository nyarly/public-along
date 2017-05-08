class AppTransaction < ActiveRecord::Base
  STATUS = ["Success", "Failure"]

  validates :emp_transaction_id,
            presence: true
  validates :application_id,
            presence: true

  belongs_to :emp_transaction
end
