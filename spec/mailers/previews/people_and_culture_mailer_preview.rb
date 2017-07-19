class PeopleAndCultureMailerPreview < ActionMailer::Preview
  def code_list_alert
    new_loc_1 = Location.find_or_create_by(code: "ABC123", name: "Aruba", status: "Active")
    new_loc_2 = Location.find_or_create_by(code: "123ABC", name: "Jamaica", status: "Active")
    PeopleAndCultureMailer.code_list_alert([new_loc_1, new_loc_2])
  end
end
