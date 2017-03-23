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
        'job_title_id',
        'manager_id',
        'location_id'))
      )",
      2.days.ago
    )
  end

  def format(attr)
    keys = [
      'hire_date',
      'contract_end_date',
      'job_title_id',
      'manager_id',
      'location_id'
    ]

    result = []

    attr.each { |k,v|
      if keys.include? k
        result << "#{k.tr("_", " ")}: #{v.present? ? Date.parse(v).strftime('%b %e, %Y') : 'nil'}" if k.include? "date"
        result << "manager: #{Employee.find_by(employee_id: v).try(:cn) || 'nil'}" if k.include? "manager"
        result << "location: #{Location.find(v).try(:name) || 'nil'}" if k.include? "location"
        if k.include?("job_title")
          jt = JobTitle.find(v)
          value = jt.present? ? "#{jt.code} - #{jt.name}" : nil
          result << "business_title: #{value}"
        end
      end
    }

    result.join( ", ")
  end
end
