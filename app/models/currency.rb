class Currency < ActiveRecord::Base
  has_many :countries

  validates :name, presence: true
  validates :iso_alpha_code, presence: true

  def code
    iso_alpha_code if iso_alpha_code.present?
  end
end
