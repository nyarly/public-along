class ConcurUploadQuery
  def initialize(relation = Employee.all)
    @relation = relation
  end

  def daily_sync_group
    upload = direct_report_changes + recent_changes + regular_worker_started_today_or_terminated_yesterday
    upload.uniq
  end

  private

  def direct_report_changes
    Employee.joins(:emp_deltas)
      .merge(EmpDelta.manager_changes
              .where("emp_delta.created_at BETWEEN ? AND ?",
                1.day.ago.beginning_of_day,
                Date.today.end_of_day))
      .select { |e| e.manager.present? }
      .map { |e| e.manager }
  end

  # Include last two days of changes to accomodate changes where
  # approver role was added for worker the previous day,
  # so approver can be assigned now.
  def recent_changes
    @relation.joins(:profiles)
              .merge(Profile.regular_worker_type)
              .joins(:emp_deltas)
              .where('emp_delta.created_at >= ?',
                2.days.ago)
  end

  def regular_worker_started_today_or_terminated_yesterday
    today = Time.now.utc
    yesterday = today - 1.day
    @relation.joins(:profiles)
             .merge(Profile.regular_worker_type)
             .where('termination_date = ?
                    OR profiles.start_date = ?
                    OR offboarded_at BETWEEN ? AND ?',
               yesterday.beginning_of_day,
               today.beginning_of_day,
               yesterday.beginning_of_day,
               today.end_of_day)
  end
end
