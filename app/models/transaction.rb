class Transaction < ActiveRecord::Base
  validates :type,
            presence: true
  validates :user_id,
            presence: true
end
