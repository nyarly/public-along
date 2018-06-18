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
    includes(employee: [profiles: [department: [:parent_org]]])
      .where("
      created_at > ?
      AND EXISTS(
      SELECT * from skeys(before) AS k
        WHERE (k IN (
        'hire_date',
        'contract_end_date',
        'job_title_id',
        'manager_id',
        'location_id',
        'department_id',
        'worker_type_id'))
      )",
        2.days.ago).sort_by do |d|
      [d.employee.current_profile.department.parent_org.name, d.employee.current_profile.department.name]
    end
  end

  def self.changes_from_last_day
    includes(employee: [profiles: [department: [:parent_org]]])
      .where("
      created_at > ?
      AND EXISTS(
      SELECT * from skeys(before) AS k
        WHERE (k IN (
        'hire_date',
        'contract_end_date',
        'job_title_id',
        'manager_id',
        'location_id',
        'department_id',
        'worker_type_id'))
      )",
        1.day.ago).sort_by do |d|
      [d.employee.current_profile.department.parent_org.name, d.employee.current_profile.department.name]
    end
  end

  def self.manager_changes
    where('before ? :key', key: 'manager_id')
  end

  def format(attr)
    keys = %w[
      hire_date
      contract_end_date
      job_title_id
      manager_id
      location_id
      department_id
      worker_type_id
    ]

    result = []

    attr.each do |k, v|
      next unless keys.include? k
      result << "#{k.tr('_', ' ')}: #{v.present? ? Date.parse(v).strftime('%b %e, %Y') : 'nil'}" if k.include? 'date'
      result << "manager: #{Employee.find_by(id: v).try(:cn) || 'nil'}" if k.include? 'manager'
      result << "location: #{Location.find_by(id: v).try(:name) || 'nil'}" if k.include? 'location'
      result << "department: #{Department.find_by(id: v).try(:name) || 'nil'}" if k.include? 'department'
      result << "worker type: #{WorkerType.find_by(id: v).try(:name) || 'nil'}" if k.include? 'worker_type'
      next unless k.include?('job_title')
      jt = JobTitle.find_by(id: v)
      value = jt.present? ? "#{jt.code} - #{jt.name}" : nil
      result << "business_title: #{value}"
    end

    result.join(', ')
  end

  def format_by_key
    before = self.before.keys
    after = self.after.keys
    results = []

    changed_attrs = (before + after).uniq

    changed_attrs.each do |a|
      row = {}
      row['name'] = format_name(a)

      if address_field?(a)
        row['before'] = ''
        row['after'] = ''
        results << row
      else
        row['before'] = format_value(a, self.before[a], created_at)
        row['after'] = format_value(a, self.after[a], created_at)
        results << row
      end
    end

    results
  end

  def format_value(k, v, date)
    value = 'blank'
    if v.present?
      value = if k.include? 'date'
                Date.parse(v).strftime('%b %-d, %Y')
              elsif k.include? 'manager_adp_employee'
                v
              elsif k.include? 'manager'
                format_manager(v, date)
              elsif k.include? 'location'
                Location.find_by(id: v).try(:name)
              elsif k.include? 'department'
                Department.find_by(id: v).try(:name)
              elsif k.include? 'worker_type'
                WorkerType.find_by(id: v).try(:name)
              elsif k.include? 'job_title'
                JobTitle.find_by(id: v).try(:name)
              else
                v
              end
    end
    value
  end

  def self.build_from_profile(prof)
    emp_before  = prof.employee.changed_attributes.deep_dup
    emp_after   = formatted_emp_delta_after(prof.employee.changes)
    prof_before = prof.changed_attributes.deep_dup
    prof_after  = formatted_emp_delta_after(prof.changes)
    before      = emp_before.except(:ancestry).merge!(prof_before)
    after       = emp_after.except(:ancestry).merge!(prof_after)

    if before.present? && after.present?
      emp_delta = EmpDelta.new(
        employee: prof.employee,
        before: before,
        after: after
      )
    end
    emp_delta
  end

  private

  def self.formatted_emp_delta_after(changes)
    Hash[changes.map { |key, value| [key, value[1]] }].with_indifferent_access
  end

  # Mezzo needs to display manager changes as firstname lastname
  # changes prior to 10/30/2017 reference manager by adp employee id
  # changes after this date reference by primary key

  def format_manager(value, date)
    if date <= Date.new(2017, 10, 30)
      manager_from_adp_employee_id(value).try(:cn)
    else
      Employee.find(value).try(:cn)
    end
  end

  def format_name(value)
    return 'Manager Employee ID' if value == 'manager_adp_employee_id'
    value.titleize
  end

  def manager_from_adp_employee_id(value)
    Employee.includes(:profiles).where(profiles: { manager_adp_employee_id: value })
  end

  # Don't show home address changes to managers
  def address_field?(key)
    %w[line_1 line_2 line_3 city state_territory postal_code country_id].include? key
  end
end
