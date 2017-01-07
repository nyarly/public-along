class EmpDelta < ActiveRecord::Base
  validates :employee_id,
            presence: true

  belongs_to :employee

  def self.report_group
    where("
      created_at > ?
      AND EXISTS(
      SELECT * from skeys(before) AS k
        WHERE (k IN (
        'hire_date',
        'contract_end_date',
        'business_title',
        'manager_id',
        'location_id')
        OR (k IN ('termination_date')
            AND (before -> 'termination_date' IS NOT NULL
                OR before -> 'termination_date' != '')
        ))
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
        result << "#{k.tr("_", " ")}: #{v.present? ? Date.parse(v).strftime('%b %e, %Y') : 'nil'}" if k.include? "date"
        result << "manager: #{Employee.find_by(employee_id: v).try(:cn) || 'nil'}" if k.include? "manager"
        result << "location: #{Location.find(v).try(:name) || 'nil'}" if k.include? "location"
        result << "#{k}: #{v}" if k.include? "business"
      end
    }

    result.join( ", ")
  end
end
