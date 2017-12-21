class ManagementTreeQuery

  def initialize(employee_node)
    @employee_node = employee_node
    @results = []
  end

  # Walks up the management tree for a given employee
  # Gathers ids for all employees above them in reporting chain.
  # Example:
  # reporting structure: ceo > manager > employee
  # Running this query on employee would return the manager id and ceo id
  # Running this query on manager would return the ceo id
  def up
    up_report_tree(@employee_node)
    @results
  end

  private

  def up_report_tree(employee)
    if employee.manager.present?
      @results << employee.manager.id
      up_report_tree(employee.manager)
    end
  end
end
