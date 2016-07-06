class Department < ActiveRecord::Base
  validates :name,
            uniqueness: true,
            presence: true
  validates :code,
            uniqueness: true

  has_many :employees

  default_scope { order('name DESC') }
end
