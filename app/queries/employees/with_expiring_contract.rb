module Employees
  class WithExpiringContract
    DEFAULT_RANGE = 2.weeks.from_now
    DEFAULT_WORKER_TYPE_KIND = 'Contractor'.freeze

    def self.call(relation = Employee.all, time_range: DEFAULT_RANGE, worker_type_kind: DEFAULT_WORKER_TYPE_KIND)
      relation
        .where(contract_end_date: time_range.beginning_of_day, termination_date: nil)
        .joins(profiles: :worker_type)
        .where(worker_types: { kind: worker_type_kind })
        .distinct
    end
  end
end
