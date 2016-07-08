class Department < ActiveRecord::Base
  validates :name,
            presence: true,
            uniqueness: true,
            case_sensitive: false
  validates :code,
            uniqueness: true,
            case_sensitive: false

  has_many :employees

  default_scope { order('name ASC') }
end
