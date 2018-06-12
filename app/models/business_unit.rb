class BusinessUnit < ActiveRecord::Base
  validates :name, presence: true
  validates :code, presence: true, uniqueness: true

  has_many :profiles
end
