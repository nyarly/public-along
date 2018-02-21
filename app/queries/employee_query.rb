class EmployeeQuery
  def initialize(relation = Employee.all)
    @relation = relation
  end

  def contract_end_reminder_group
    @relation.where("contract_end_date = ?
                     AND status LIKE ?
                     AND termination_date IS NULL",
      2.weeks.from_now.beginning_of_day,
      'active')
  end

  def active_regular_workers
    Employee.where(status: 'active').joins(:profiles).merge(Profile.regular_worker_type).to_a.uniq
  end

  def concur_upload_group
    upload = regular_worker_changed_since_yesterday + regular_worker_started_today_or_terminated_yesterday
    upload.uniq
  end

  private

  def regular_worker_changed_since_yesterday
    @relation.joins(:profiles)
              .merge(Profile.regular_worker_type)
              .joins(:emp_deltas)
              .where('emp_delta.created_at >= ?',
                1.day.ago)
  end

  def regular_worker_started_today_or_terminated_yesterday
    today = Time.now.utc
    yesterday = today - 1.day
    @relation.joins(:profiles)
             .merge(Profile.regular_worker_type)
             .where('termination_date = ?
                    OR profiles.start_date = ?',
               yesterday.beginning_of_day,
               today.beginning_of_day)
              2.weeks.from_now.beginning_of_day,
              'active')
  end

  # P&C wants an alert for contract end dates 3 weeks in advance
  def hr_contractor_notices
    @relation.where("contract_end_date = ?
                     AND status LIKE ?
                     AND termination_date IS NULL",
              3.weeks.from_now.beginning_of_day,
              'active')
  end
end
