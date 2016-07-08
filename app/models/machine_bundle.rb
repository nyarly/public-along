class MachineBundle < ActiveRecord::Base
  validates :name,
            presence: true,
            uniqueness: true,
            case_sensitive: false
  validates :description,
            presence: true
end
