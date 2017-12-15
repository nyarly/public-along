require 'rails_helper'

describe Report::Onboard::Daily, type: :model do
  let!(:start_date)   { DateTime.new(2018, 1, 1, 0, 0, 0) }
  let!(:manager)      { FactoryGirl.create(:employee) }
  let(:buddy)         { FactoryGirl.create(:employee, email: "buddy@example.com") }
  let(:parent_org_1)  { FactoryGirl.create(:parent_org, name: "Aaa") }
  let(:parent_org_2)  { FactoryGirl.create(:parent_org, name: "Bbb") }
  let(:dept_1)        { FactoryGirl.create(:department,
                        parent_org: parent_org_1,
                        name: "Ccc") }
  let(:dept_2)        { FactoryGirl.create(:department,
                        parent_org: parent_org_2,
                        name: "Ddd") }
  let(:dept_3)        { FactoryGirl.create(:department,
                        parent_org: parent_org_2,
                        name: "Eee") }
  let!(:new_hire_1)   { FactoryGirl.create(:employee,
                        created_at: 1.month.ago,
                        email: "new_hire_1@example.com",
                        status: "pending",
                        hire_date: start_date,
                        manager: manager) }
  let!(:new_hire_p_1) { FactoryGirl.create(:profile,
                        created_at: 1.month.ago,
                        start_date: start_date,
                        profile_status: "pending",
                        employee: new_hire_1,
                        department: dept_1) }
  let!(:onboard)      { FactoryGirl.create(:emp_transaction,
                        kind: "Onboarding",
                        created_at: 3.days.ago,
                        employee: new_hire_1) }
  let!(:onboard_info) { FactoryGirl.create(:onboarding_info,
                        created_at: 3.days.ago,
                        emp_transaction: onboard,
                        buddy_id: buddy.id) }
  let!(:new_hire_2)   { FactoryGirl.create(:employee,
                        email: "new_hire_2@example.com",
                        status: "pending",
                        hire_date: start_date,
                        manager: manager) }
  let!(:new_hire_p_2) { FactoryGirl.create(:profile,
                        start_date: start_date,
                        profile_status: "pending",
                        employee: new_hire_2,
                        department: dept_3) }
  let!(:rehire)       { FactoryGirl.create(:employee,
                        created_at: 3.years.ago,
                        status: "pending",
                        email: "rehire@example.com",
                        hire_date: 3.years.ago,
                        request_status: "waiting") }
  let!(:rehire_new_p) { FactoryGirl.create(:profile,
                        created_at: 2.weeks.ago,
                        profile_status: "pending",
                        employee: rehire,
                        start_date: start_date,
                        department: dept_2) }
  let!(:rehire_old_p) { FactoryGirl.create(:terminated_profile,
                        created_at: 3.years.ago,
                        employee: rehire,
                        start_date: 3.years.ago) }

  it "should have correct formatting" do
    expect(Spreadsheet.client_encoding).to eq("UTF-8")
  end

  it "should create report with correct info" do
    Report::Onboard::Daily.new
    book = Spreadsheet.open "tmp/reports/onboard/daily_" + DateTime.now.strftime('%Y%m%d') + ".xls"
    sheet = book.worksheet 'daily'

    expect(sheet.rows.count).to eq(4)
    expect(sheet.rows[0].length).to eq(16)
    expect(sheet.rows[1].length).to eq(16)

    expect(sheet.rows[0]).to eq([
      "ParentOrg",
      "Department",
      "Name",
      "EmployeeID",
      "EmployeeType",
      "Position",
      "Manager",
      "WorkLocation",
      "OnboardingFormDueOn",
      "OnboardingFormSubmittedOn",
      "Email",
      "BuddyName",
      "BuddyEmail",
      "StartDate",
      "ContractEndDate",
      "LastModifiedAt"
    ])
    expect(sheet.rows[1]).to eq([
      "Aaa",
      "Ccc",
      "#{new_hire_1.cn}",
      "#{new_hire_1.current_profile.adp_employee_id}",
      "#{new_hire_1.worker_type.name}",
      "#{new_hire_1.job_title.name}",
      "#{manager.cn}",
      "#{new_hire_1.location.name}",
      (new_hire_1.onboarding_due_date.to_datetime - DateTime.new(1899, 12, 30, 0, 0, 0)).to_f,
      (onboard.created_at.to_datetime - DateTime.new(1899, 12, 30, 0, 0, 0)).to_f,
      "new_hire_1@example.com",
      "#{buddy.cn}",
      "buddy@example.com",
      ((start_date) - DateTime.new(1899, 12, 30, 0, 0, 0)).to_f,
      nil,
      (onboard_info.created_at.to_datetime - DateTime.new(1899, 12, 30, 0, 0, 0)).to_f
    ])
    expect(sheet.rows[2]).to eq([
      "Bbb",
      "Ddd",
      "#{rehire.cn}",
      "#{rehire.current_profile.adp_employee_id}",
      "#{rehire.worker_type.name}",
      "#{rehire.job_title.name}",
      nil,
      "#{rehire.location.name}",
      (rehire.onboarding_due_date.to_datetime - DateTime.new(1899, 12, 30, 0, 0, 0)).to_f,
      nil,
      "rehire@example.com",
      nil,
      nil,
      ((start_date) - DateTime.new(1899, 12, 30, 0, 0, 0)).to_f,
      nil,
      (rehire_new_p.created_at.to_datetime - DateTime.new(1899, 12, 30, 0, 0, 0)).to_f
    ])
    expect(sheet.rows[3]).to eq([
      "Bbb",
      "Eee",
      "#{new_hire_2.cn}",
      "#{new_hire_2.current_profile.adp_employee_id}",
      "#{new_hire_2.worker_type.name}",
      "#{new_hire_2.job_title.name}",
      "#{manager.cn}",
      "#{new_hire_2.location.name}",
      (new_hire_2.onboarding_due_date.to_datetime - DateTime.new(1899, 12, 30, 0, 0, 0)).to_f,
      nil,
      "new_hire_2@example.com",
      nil,
      nil,
      ((start_date) - DateTime.new(1899, 12, 30, 0, 0, 0)).to_f,
      nil,
      (new_hire_p_2.created_at.to_datetime - DateTime.new(1899, 12, 30, 0, 0, 0)).to_f
    ])
  end

  it "format the cells with background color and number format" do
    Report::Onboard::Daily.new
    book = Spreadsheet.open "tmp/reports/onboard/daily_" + DateTime.now.strftime('%Y%m%d') + ".xls"
    sheet = book.worksheet 'daily'

    expect(sheet.row(0).format(8).pattern_fg_color).to eq(:border)
    expect(sheet.row(0).format(8).number_format).to eq("GENERAL")
    expect(sheet.row(1).format(8).pattern_fg_color).to eq(:border)
    expect(sheet.row(1).format(8).number_format).to eq("YYYY-MM-DD")
    expect(sheet.row(2).format(8).pattern_fg_color).to eq(:border)
    expect(sheet.row(2).format(8).number_format).to eq("YYYY-MM-DD")
    expect(sheet.row(3).format(8).pattern_fg_color).to eq(:yellow)
    expect(sheet.row(3).format(8).number_format).to eq("YYYY-MM-DD")

    expect(sheet.row(0).format(9).pattern_fg_color).to eq(:border)
    expect(sheet.row(0).format(9).number_format).to eq("GENERAL")
    expect(sheet.row(1).format(9).pattern_fg_color).to eq(:border)
    expect(sheet.row(1).format(9).number_format).to eq("YYYY-MM-DD hh:mm:ss")
    expect(sheet.row(2).format(9).pattern_fg_color).to eq(:border)
    expect(sheet.row(2).format(9).number_format).to eq("YYYY-MM-DD hh:mm:ss")
    expect(sheet.row(3).format(9).pattern_fg_color).to eq(:yellow)
    expect(sheet.row(3).format(9).number_format).to eq("YYYY-MM-DD hh:mm:ss")
  end
end
