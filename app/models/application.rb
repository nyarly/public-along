class Application < ActiveRecord::Base
  validates :name,
            presence: true
  has_many :access_levels
end
