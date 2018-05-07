module NewHireHelper
  def onboard_link(employee)
    transaction = employee.onboarding_infos.last.try(:emp_transaction)
    if transaction
      link_to 'Form', emp_transaction_path(transaction)
    end
  end
end
