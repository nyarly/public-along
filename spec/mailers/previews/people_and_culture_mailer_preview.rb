class PeopleAndCultureMailerPreview < ActionMailer::Preview
  def code_list_alert
    new_loc_1 = Location.find_or_create_by(code: "ABC123", name: "Aruba", status: "Active")
    new_loc_2 = Location.find_or_create_by(code: "123ABC", name: "Jamaica", status: "Active")
    PeopleAndCultureMailer.code_list_alert([new_loc_1, new_loc_2])
  end

  def terminate_contract
    e = Employee.where("contract_end_date IS NOT NULL").last
    PeopleAndCultureMailer.terminate_contract(e)
  end

  def upcoming_contract_end
    e = Employee.where("contract_end_date IS NOT NULL").last
    PeopleAndCultureMailer.upcoming_contract_end(e)
  end
end
