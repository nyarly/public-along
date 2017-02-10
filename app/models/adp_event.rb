class AdpEvent < ActiveRecord::Base
  STATUS = ["New", "Processed"]
  validates :json,
            presence: true
  validates :msg_id,
            presence: true
  validates :status,
            inclusion: { in: STATUS }
end
