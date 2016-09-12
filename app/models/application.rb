class Application < ActiveRecord::Base
  validates :name,
            presence: true
  has_many :access_levels, dependent: :destroy
end
