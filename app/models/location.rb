class Location < ActiveRecord::Base
  KINDS = ["Office", "Remote Location"]
  COUNTRIES = ["AU", "CA", "DE", "GB", "IE", "IN", "JP", "MX", "US"]

  validates :name,
            presence: true,
            uniqueness: true,
            case_sensitive: false
  validates :kind,
            presence: true,
            inclusion: { in: KINDS }
  validates :country,
            presence: true,
            inclusion: { in: COUNTRIES }
end
