class EmpDelta < ActiveRecord::Base
  validates :employee_id,
            presence: true

  belongs_to :employee

  def self.important_changes
    where("(before ?| ARRAY['department_id', 'location_id', 'worker_type_id', 'job_title_id']
        OR after ?| ARRAY['department_id', 'location_id', 'worker_type_id', 'job_title_id'])")
  end

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
      'location_id',
      'department_id',
      'worker_type_id'
    ]

    result = []

    attr.each { |k,v|
      if keys.include? k
        result << "#{k.tr("_", " ")}: #{v.present? ? Date.parse(v).strftime('%b %e, %Y') : 'nil'}" if k.include? "date"
        result << "manager: #{Employee.find_by(employee_id: v).try(:cn) || 'nil'}" if k.include? "manager"
        result << "location: #{Location.find(v).try(:name) || 'nil'}" if k.include? "location"
        result << "department: #{Department.find(v).try(:name) || 'nil'}" if k.include? "department"
        result << "worker type: #{WorkerType.find(v).try(:name) || 'nil'}" if k.include? "worker_type"
        if k.include?("job_title")
          jt = JobTitle.find(v)
          value = jt.present? ? "#{jt.code} - #{jt.name}" : nil
          result << "business_title: #{value}"
        end
      end
    }

    result.join( ", ")
  end

  def format_by_key
    before = self.before.keys
    after = self.after.keys
    results = []

    changed_attrs = (before + after).uniq

    changed_attrs.each do |a|
      row = {}
      row["name"] = a.titleize
      row["before"] = self.format_value(a, self.before[a])
      row["after"] = self.format_value(a, self.after[a])
      results << row
    end

    results
  end

  def format_value(k, v)
    value = 'blank'
    if v.present?
      if k.include? "date"
        value = Date.parse(v).strftime('%b %-d, %Y')
      elsif k.include? "manager"
        value = Employee.find_by(employee_id: v).try(:cn)
      elsif k.include? "location"
        value = Location.find(v).try(:name)
      elsif k.include? "department"
        value = Department.find(v).try(:name)
      elsif k.include? "worker_type"
        value = WorkerType.find(v).try(:name)
      elsif k.include? "job_title"
        value = JobTitle.find(v).try(:name)
      else
        value = v
      end
    end
    value
  end
end
