class WorkerType < ActiveRecord::Base
  KINDS = ["Regular", "Contingent"]
  STATUS = ["Active", "Inactive"]

  validates :name,
            presence: true
  validates :code,
            presence: true,
            uniqueness: true,
            case_sensitive: false
  validates :kind,
            presence: true,
            inclusion: { in: KINDS + ["Pending Assignment"] }
  validates :status,
            inclusion: { in: STATUS }
end
