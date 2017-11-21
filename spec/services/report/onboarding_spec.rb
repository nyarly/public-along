require 'rails_helper'

describe Report::Onboarding, type: :service do
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
                        email: "new_hire_1@example.com",
                        status: "pending",
                        hire_date: 1.week.from_now,
                        manager: manager) }
  let!(:new_hire_p_1) { FactoryGirl.create(:profile,
                        start_date: 1.week.from_now,
                        profile_status: "pending",
                        employee: new_hire_1,
                        department: dept_1) }
  let!(:onboard)      { FactoryGirl.create(:emp_transaction,
                        kind: "Onboarding",
                        employee: new_hire_1) }
  let!(:onboard_info) { FactoryGirl.create(:onboarding_info,
                        emp_transaction: onboard,
                        buddy_id: buddy.id) }
  let!(:new_hire_2)   { FactoryGirl.create(:employee,
                        email: "new_hire_2@example.com",
                        status: "pending",
                        hire_date: 2.weeks.from_now,
                        manager: manager) }
  let!(:new_hire_p_2) { FactoryGirl.create(:profile,
                        start_date: 2.weeks.from_now,
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
                        start_date: 1.week.from_now,
                        department: dept_2) }
  let!(:rehire_old_p) { FactoryGirl.create(:terminated_profile,
                        created_at: 3.years.ago,
                        employee: rehire,
                        start_date: 3.years.ago) }
  let(:report)        { Report::Onboarding.new }

  it "should call the correct Employee scope" do
    expect(Profile).to receive(:onboarding_report_group).and_return([new_hire_p_1, new_hire_p_2, rehire_new_p])
    report.create
  end

  it "should create report with correct info" do
    report.create
    book = Spreadsheet.open "tmp/reports/onboarding_" + DateTime.now.strftime('%Y%m%d') + ".xls"
    sheet =  book.worksheet 'Onboards'

    expect(sheet.rows.count).to eq(4)
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
      "LastModified"
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
      "#{new_hire_1.onboarding_due_date}",
      "#{onboard.created_at.try(:strftime, "%b %e, %Y at %H:%M:%S")}",
      "new_hire_1@example.com",
      "#{buddy.cn}",
      "buddy@example.com",
      "#{1.week.from_now.strftime("%b %e, %Y")}",
      nil,
      "#{onboard.created_at.try(:strftime, "%b %e, %Y at %H:%M:%S")}"
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
      "#{rehire.onboarding_due_date}",
      nil,
      "rehire@example.com",
      nil,
      nil,
      "#{1.week.from_now.strftime("%b %e, %Y")}",
      nil,
      "#{rehire_new_p.created_at.try(:strftime, "%b %e, %Y at %H:%M:%S")}"
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
      "#{new_hire_2.onboarding_due_date}",
      nil,
      "new_hire_2@example.com",
      nil,
      nil,
      "#{2.weeks.from_now.strftime("%b %e, %Y")}",
      nil,
      "#{new_hire_2.created_at.try(:strftime, "%b %e, %Y at %H:%M:%S")}"])
  end
end
