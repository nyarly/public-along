class Employee < ActiveRecord::Base
  validates :first_name,
            presence: true
  validates :last_name,
            presence: true
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false }
end
