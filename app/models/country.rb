class Country < ActiveRecord::Base
  belongs_to :currency
  has_many :addresses

  validates :name, presence: true
  validates :iso_alpha_2, presence: true, uniqueness: true
  validates :iso_alpha_3, uniqueness: true

  scope :code_collection, -> { all.pluck(:iso_alpha_3) }
end
