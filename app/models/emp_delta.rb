class EmpDelta < ActiveRecord::Base
  validates :employee_id,
            presence: true

  belongs_to :employee

  def self.report_group
    where("EXISTS(SELECT * from skeys(before)
      AS k
      WHERE k IN (
      'hire_date',
      'contract_end_date',
      'business_title',
      'manager_id',
      'location_id')
      OR (k = 'termination_date'
      AND before -> 'termination_date' IS NOT NULL
      AND before -> 'termination_date' != '')
      AND created_at > ?
      )",
      2.days.ago
    )
  end

  def format(attr)
    keys = [
      'hire_date',
      'contract_end_date',
      'termination_date',
      'business_title',
      'manager_id',
      'location_id'
    ]

    result = []

    attr.each { |k,v|
      if keys.include? k
        result << "#{k.tr("_", " ")}: #{Date.parse(v).strftime('%b %e, %Y')}" if k.include? "date"
        result << "manager: #{Employee.find(v).try(:cn)}" if k.include? "manager"
        result << "location: #{Location.find(v).try(:name)}" if k.include? "location"
        result << "#{k}: #{v}" if k.include? "business"
      end
    }

    result.join( ", ")
  end
end
