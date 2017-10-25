class ManagementTreeQuery
  def initialize(root_employee)
    @root_employee = root_employee
    @results = []
  end

  def call
    report_tree(@root_employee)
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
