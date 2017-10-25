class ManagementTreeQuery

  # Walks up the management tree for a given employee
  # and gathers ids for all employees above them in reporting chain.
  # Example:
  # reporting structure: ceo > manager > employee
  # Running this query on employee would return the manager id and ceo id
  # Running this query on manager would return the ceo id

  def initialize(employee_node)
    @employee_node = employee_node
    @results = []
  end

  def call
    report_tree(@employee_node)
    @results
  end

  private

  def report_tree(employee)
    if employee.manager.present?
      @results << employee.manager.id
      report_tree(employee.manager)
    end
  end
end
