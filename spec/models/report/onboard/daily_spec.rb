require 'rails_helper'

describe Report::Onboard::Daily, type: :model do
  let!(:manager)      { FactoryGirl.create(:employee) }
  let(:buddy)         { FactoryGirl.create(:employee, email: 'buddy@example.com') }
  let(:parent_org_1)  { FactoryGirl.create(:parent_org, name: 'Aaa') }
  let(:parent_org_2)  { FactoryGirl.create(:parent_org, name: 'Bbb') }

  let(:dept_1) do
    FactoryGirl.create(:department,
      parent_org: parent_org_1,
      name: 'Ccc')
  end

  let(:dept_2) do
    FactoryGirl.create(:department,
      parent_org: parent_org_2,
      name: 'Ddd')
  end

  let(:dept_3) do
    FactoryGirl.create(:department,
      parent_org: parent_org_2,
      name: 'Eee')
  end

  let!(:new_hire_1) do
    FactoryGirl.create(:employee,
      created_at: Date.new(2018, 1, 1),
      email: 'new_hire_1@example.com',
      status: 'pending',
      hire_date: Date.new(2018, 2, 3),
      manager: manager)
  end

  let!(:new_hire_p_1) do
    FactoryGirl.create(:profile,
      created_at: Date.new(2018, 1, 1),
      start_date: Date.new(2018, 2, 3),
      profile_status: 'pending',
      employee: new_hire_1,
      department: dept_1,
      adp_employee_id: '8642')
  end

  let!(:onboard) do
    FactoryGirl.create(:emp_transaction,
      kind: 'Onboarding',
      created_at: Time.new(2018, 1, 31, 5, 0, 0, '+00:00'),
      employee: new_hire_1)
  end

  let!(:onboard_info) do
    FactoryGirl.create(:onboarding_info,
      created_at: Time.new(2018, 1, 31, 5, 0, 0, '+00:00'),
      emp_transaction: onboard,
      buddy_id: buddy.id)
  end

  let!(:new_hire_2)   do
    FactoryGirl.create(:employee,
      email: 'new_hire_2@example.com',
      status: 'pending',
      hire_date: Date.new(2018, 2, 3),
      manager: manager)
  end

  let!(:new_hire_p_2) do
    FactoryGirl.create(:profile,
      start_date: Date.new(2018, 2, 3),
      profile_status: 'pending',
      employee: new_hire_2,
      department: dept_3,
      adp_employee_id: '109988',
      created_at: Date.new(2018, 2, 1))
  end

  let!(:rehire) do
    FactoryGirl.create(:employee,
      created_at: Date.new(2016, 1, 1),
      status: 'pending',
      email: 'rehire@example.com',
      hire_date: Date.new(2016, 1, 1),
      request_status: 'waiting')
  end

  let!(:rehire_new_p) do
    FactoryGirl.create(:profile,
      created_at: Date.new(2018, 1, 1),
      profile_status: 'pending',
      employee: rehire,
      start_date: Date.new(2018, 2, 3),
      department: dept_2,
      adp_employee_id: '3579')
  end

  let!(:rehire_old_p) do
    FactoryGirl.create(:terminated_profile,
      created_at: Date.new(2016, 1, 1),
      employee: rehire,
      start_date: Date.new(2016, 1, 1))
  end
  let(:report) { Report::Onboard::Daily.new }

  before do
    Timecop.freeze(Time.new(2018, 2, 1, 0, 0, 0, '-08:00'))
  end

  after do
    Timecop.return
  end

  it 'has right number of cells' do
    Report::Onboard::Daily.new
    book = Roo::Spreadsheet.open('tmp/reports/onboard/daily_' + DateTime.now.strftime('%Y%m%d') + '.xlsx')
    sheet = book.sheet('daily')

    expect(sheet.row(2).length).to eq(16)
  end

  it 'has the right headers' do
    Report::Onboard::Daily.new
    book = Roo::Spreadsheet.open('tmp/reports/onboard/daily_' + DateTime.now.strftime('%Y%m%d') + '.xlsx')
    sheet = book.sheet('daily')

    expect(sheet.row(1)).to eq([
      'Parent Org',
      'Department',
      'Name',
      'Employee ID',
      'Employee Type',
      'Position',
      'Manager',
      'Location',
      'Onboarding Form Due',
      'Onboarding Form Submitted',
      'Email',
      'Buddy',
      'Buddy Email',
      'Start Date',
      'Contract End Date',
      'Last Modified'
    ])
  end

  it 'has rows with correct content and order' do
    Report::Onboard::Daily.new
    book = Roo::Spreadsheet.open 'tmp/reports/onboard/daily_' + DateTime.now.strftime('%Y%m%d') + '.xlsx'
    sheet = book.sheet('daily')

    expect(sheet.row(2)).to eq([
      'Aaa',
      'Ccc',
      "#{new_hire_1.cn}",
      8642,
      "#{new_hire_1.worker_type.name}",
      "#{new_hire_1.job_title.name}",
      "#{manager.cn}",
      "#{new_hire_1.location.name}",
      new_hire_1.onboarding_due_date.to_date,
      onboard.created_at.to_datetime,
      'new_hire_1@example.com',
      "#{buddy.cn}",
      'buddy@example.com',
      Date.new(2018, 2, 3),
      nil,
      onboard_info.created_at.to_datetime
    ])
    expect(sheet.row(3)).to eq([
      'Bbb',
      'Ddd',
      "#{rehire.cn}",
      3579,
      "#{rehire.worker_type.name}",
      "#{rehire.job_title.name}",
      nil,
      "#{rehire.location.name}",
      rehire.onboarding_due_date.to_date,
      nil,
      "rehire@example.com",
      nil,
      nil,
      Date.new(2018, 2, 3),
      nil,
      rehire_new_p.created_at.to_datetime
    ])
    expect(sheet.row(4)).to eq([
      'Bbb',
      'Eee',
      "#{new_hire_2.cn}",
      109988,
      "#{new_hire_2.worker_type.name}",
      "#{new_hire_2.job_title.name}",
      "#{manager.cn}",
      "#{new_hire_2.location.name}",
      new_hire_2.onboarding_due_date.to_date,
      nil,
      "new_hire_2@example.com",
      nil,
      nil,
      Date.new(2018, 2, 3),
      nil,
      new_hire_p_2.created_at.to_datetime
    ])
  end

  it 'formats regular worker cells' do
    expect(report.worker_row_styles(new_hire_1)).to eq([nil, nil, nil, nil, nil, nil, nil, nil, 7, 8, nil, nil, nil, 7, 7, 8])
  end

  it 'formats new worker record cells' do
    expect(report.worker_row_styles(new_hire_2)).to eq([6, 6, 6, 6, 6, 6, 6, 6, 4, 5, 6, 6, 6, 4, 4, 5])
  end
end
