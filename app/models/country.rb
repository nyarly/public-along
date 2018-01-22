class Country < ActiveRecord::Base
  belongs_to :currency
  has_many :addresses

  validates :name, presence: true
  validates :iso_alpha_2_code, presence: true, uniqueness: true

  def code
    iso_alpha_2_code if iso_alpha_2_code.present?
  end
end
