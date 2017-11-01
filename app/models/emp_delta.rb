class EmpDelta < ActiveRecord::Base
  validates :employee_id,
            presence: true

  belongs_to :employee

  def self.important_changes
    where("(before ?| ARRAY['department_id', 'location_id', 'worker_type_id', 'job_title_id']
        OR after ?| ARRAY['department_id', 'location_id', 'worker_type_id', 'job_title_id'])")
  end

  # temporary way to exclude emp deltas that have blank values
  # remove this code when the database has been cleaned up
  def self.bad_deltas
    where("before = '' AND after = ''")
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
        result << "manager: #{Employee.find_by(id: v).try(:cn) || 'nil'}" if k.include? "manager"
        result << "location: #{Location.find_by(id: v).try(:name) || 'nil'}" if k.include? "location"
        result << "department: #{Department.find_by(id: v).try(:name) || 'nil'}" if k.include? "department"
        result << "worker type: #{WorkerType.find_by(id: v).try(:name) || 'nil'}" if k.include? "worker_type"
        if k.include?("job_title")
          jt = JobTitle.find_by(id: v)
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

      if is_address_field?(a)
        row["before"] = ''
        row["after"] = ''
        results << row
      else
        row["before"] = self.format_value(a, self.before[a], self.created_at)
        row["after"] = self.format_value(a, self.after[a], self.created_at)
        results << row
      end
    end

    results
  end

  def format_value(k, v, date)
    value = 'blank'
    if v.present?
      if k.include? "date"
        value = Date.parse(v).strftime('%b %-d, %Y')
      elsif k.include? "manager"
        value = format_manager(v, date)
      elsif k.include? "location"
        value = Location.find_by(id: v).try(:name)
      elsif k.include? "department"
        value = Department.find_by(id: v).try(:name)
      elsif k.include? "worker_type"
        value = WorkerType.find_by(id: v).try(:name)
      elsif k.include? "job_title"
        value = JobTitle.find_by(id: v).try(:name)
      else
        value = v
      end
    end
    value
  end

  def self.build_from_profile(prof)
    emp_before  = prof.employee.changed_attributes.deep_dup
    emp_after   = Hash[prof.employee.changes.map { |k,v| [k, v[1]] }]
    prof_before = prof.changed_attributes.deep_dup
    prof_after  = Hash[prof.changes.map { |k,v| [k, v[1]] }]
    before      = emp_before.merge!(prof_before)
    after       = emp_after.merge!(prof_after)

    if before.present? and after.present?
      emp_delta = EmpDelta.new(
        employee: prof.employee,
        before: before,
        after: after
      )
    end
    emp_delta
  end

  private

  # Mezzo needs to display manager changes as firstname lastname
  # changes prior to 10/30/2017 reference manager by adp employee id
  # changes after this date reference by primary key

  def format_manager(value, date)
    if date <= Date.new(2017, 10, 30)
      Employee.find_by_employee_id(value).try(:cn)
    else
      Employee.find_by(id: value).try(:cn)
    end
  end

  # Don't show home address changes to managers
  def is_address_field?(key)
    ["home_address_1", "home_address_2", "home_city", "home_state", "home_zip"].include? key
  end

end
