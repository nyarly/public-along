class AccessLevel < ActiveRecord::Base
  validates :name,
            presence: true
  validates :application_id,
            presence: true

  belongs_to :application
  has_many :sec_prof_access_levels # on_delete: :cascade in db
  has_many :security_profiles, through: :sec_prof_access_levels

  def display_name
    "#{application.name} - #{name}"
  end
end
