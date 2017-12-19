class ActivityFeedQuery
  def initialize(employee)
    @employee = employee
    @activities = []
  end

  def all
    get_emp_deltas
    get_emp_transactions
    @activities.sort_by!(&:created_at).reverse!
  end

  private

  def get_emp_deltas
    @employee.emp_deltas.map { |e| @activities << e }
    @activities = @activities - @employee.emp_deltas.bad_deltas
  end

  def get_emp_transactions
    @employee.emp_transactions.map { |e| @activities << e }
  end
end
