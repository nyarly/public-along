require 'rails_helper'

RSpec.describe EmpDelta, type: :model do
  let(:employee) { FactoryGirl.create(:regular_employee)}
  let(:job_title) { FactoryGirl.create(:job_title)}

  let(:emp_delta) { FactoryGirl.build(:emp_delta,
    employee_id: employee.id
  )}

  it "should meet validations" do
    expect(emp_delta).to be_valid

    expect(emp_delta).to_not allow_value(nil).for(:employee_id)
  end

  context "report group" do
    let!(:report_group) {[
      FactoryGirl.create(:emp_delta,
        before: {
          "leave_start_date" => Date.today,
          "hire_date" => Date.today},
        after: {
          "leave_start_date" => Date.tomorrow,
          "hire_date" => Date.tomorrow}
      ),
      FactoryGirl.create(:emp_delta,
        before: {"contract_end_date" => Date.today},
        after: {"contract_end_date" => Date.tomorrow}
      ),
      FactoryGirl.create(:emp_delta,
        before: {"job_title_id" => "some number"},
        after: {"job_title_id" => "some number"}
      ),
      FactoryGirl.create(:emp_delta,
        before: {"manager_id" => "some number"},
        after: {"manager_id" => "some number"}
      ),
      FactoryGirl.create(:emp_delta,
        before: {"location_id" => "some number"},
        after: {"location_id" => "some number"},
        created_at: Date.yesterday
      )
    ]}


    let!(:non_report) {[
      FactoryGirl.create(:emp_delta,
        before: {"leave_start_date" => Date.today},
        after: {"leave_start_date" => Date.tomorrow}
      ),
      FactoryGirl.create(:emp_delta,
        before: {"first_name" => "some name"},
        after: {"first_name" => "some name"}
      ),
      FactoryGirl.create(:emp_delta,
        before: {"department_id" => "some dept"},
        after: {"department_id" => "some dept"}
      ),
      FactoryGirl.create(:emp_delta,
        before: {"employee_id" => "some number"},
        after: {"employee_id" => "some number"}
      ),
      FactoryGirl.create(:emp_delta,
        before: {"termination_date" => Date.today},
        after: {"termination_date" => nil}
      ),
      FactoryGirl.create(:emp_delta,
        before: {"termination_date" => nil},
        after: {"termination_date" => Date.today}
      ),
      FactoryGirl.create(:emp_delta,
        before: {"termination_date" => ""},
        after: {"termination_date" => Date.today},
        created_at: 2.days.ago
      ),
      FactoryGirl.create(:emp_delta,
        before: {"termination_date" => Date.yesterday},
        after: {"termination_date" => Date.today},
        created_at: 2.days.ago
      )
    ]}

    it "should include the correct data" do
      expect(EmpDelta.report_group).to match_array(report_group)
      expect(EmpDelta.report_group).to_not include(non_report)
    end
  end

  context "format attributes" do
    it "should only format select attributes" do
      delta = FactoryGirl.create(:emp_delta,
        before: {
          "leave_start_date" => Date.today,
          "hire_date" => 1.week.ago,
          "contract_end_date" => 1.month.from_now},
        after: {
          "leave_start_date" => Date.tomorrow,
          "hire_date" => Date.tomorrow,
          "contract_end_date" => 6.months.from_now}
      )

      expect(delta.format(delta.before)).to include("hire date: #{1.week.ago.strftime('%b %e, %Y')}")
      expect(delta.format(delta.before)).to include("contract end date: #{1.month.from_now.strftime('%b %e, %Y')}")
      expect(delta.format(delta.before)).to_not include("leave start date")
      expect(delta.format(delta.after)).to include("hire date: #{Date.tomorrow.strftime('%b %e, %Y')}")
      expect(delta.format(delta.after)).to include("contract end date: #{6.months.from_now.strftime('%b %e, %Y')}")
      expect(delta.format(delta.after)).to_not include("leave start date")
    end

    it "should sub names for ids" do
      old_mgr = FactoryGirl.create(:regular_employee)
      new_mgr = FactoryGirl.create(:regular_employee)
      old_loc = FactoryGirl.create(:location)
      new_loc = FactoryGirl.create(:location)
      old_jt = FactoryGirl.create(:job_title)
      new_jt = FactoryGirl.create(:job_title)
      delta = FactoryGirl.create(:emp_delta,
        before: {
          "location_id" => old_loc.id,
          "manager_id" => old_mgr.id,
          "job_title_id" => old_jt.id},
        after: {
          "manager_id" => new_mgr.id,
          "job_title_id" => new_jt.id,
          "location_id" => new_loc.id}
      )

      expect(delta.format(delta.before)).to include("manager: #{old_mgr.cn}")
      expect(delta.format(delta.before)).to include("location: #{old_loc.name}")
      expect(delta.format(delta.before)).to include("business_title: #{old_jt.code} - #{old_jt.name}")
      expect(delta.format(delta.after)).to include("manager: #{new_mgr.cn}")
      expect(delta.format(delta.after)).to include("location: #{new_loc.name}")
      expect(delta.format(delta.after)).to include("business_title: #{new_jt.code} - #{new_jt.name}")
    end

    it "should format dates" do
      new_term_date = Date.new(2017, 12, 12)
      delta = FactoryGirl.create(:emp_delta,
        before: {
          "hire_date" => nil},
        after: {
          "hire_date" => new_term_date}
      )

      expect(delta.format(delta.before)).to include("hire date: nil")
      expect(delta.format(delta.after)).to include("hire date: Dec 12, 2017")
    end

    it "should sub nil if it can't find the activerecord object" do
      new_mgr = FactoryGirl.create(:active_employee)
      mgr_prof = FactoryGirl.create(:active_profile, employee: new_mgr, adp_employee_id: "111111")
      new_loc = FactoryGirl.create(:location)
      new_term_date = Date.new(2017, 12, 12)
      delta = FactoryGirl.create(:emp_delta,
        before: {
          "manager_id" => nil,
          "location_id" => nil,
          "hire_date" => nil},
        after: {
          "manager_id" => new_mgr.id,
          "location_id" => new_loc.id,
          "hire_date" => new_term_date}
      )

      expect(delta.format(delta.before)).to include("location: nil")
      expect(delta.format(delta.before)).to include("manager: nil")
      expect(delta.format(delta.before)).to include("hire date: nil")
      expect(delta.format(delta.after)).to include("manager: #{new_mgr.cn}")
      expect(delta.format(delta.after)).to include("location: #{new_loc.name}")
      expect(delta.format(delta.after)).to include("hire date: Dec 12, 2017")
    end
  end

  context "format by value" do
    it "should collect the values and format them" do
      old_location = FactoryGirl.create(:location, name: "Boston")
      old_department = FactoryGirl.create(:department, name: "Backend Product")
      new_location = FactoryGirl.create(:location, name: "Los Angeles")
      new_department = FactoryGirl.create(:department, name: "Infrastructure")

      delta_a = FactoryGirl.create(:emp_delta,
        before: {
          "location_id" => old_location.id,
          "department_id" => old_department.id },
        after: {
          "location_id" => new_location.id,
          "department_id" => new_department.id })

      delta_b = FactoryGirl.create(:emp_delta,
        before: { "contract_end_date" => nil },
        after: { "contract_end_date" => Date.new(2018, 5, 6) })

      delta_c = FactoryGirl.create(:emp_delta,
        before: {},
        after: {"office_phone" => "888-888-8888"})

      formatted_results = [
        {'name'=>'Location', 'before'=>'Boston', 'after'=>'Los Angeles'},
        {'name'=>'Department', 'before'=>'Backend Product', 'after'=>'Infrastructure'}]

      expect(delta_a.format_by_key).to eq(formatted_results)
      expect(delta_b.format_by_key).to eq([{'name'=>'Contract End Date', 'before'=> 'blank', 'after'=>'May 6, 2018'}])
      expect(delta_c.format_by_key).to eq([{'name'=>'Office Phone', 'before'=> 'blank', 'after'=>'888-888-8888'}])
    end
  end

  context "build from profile" do
    let(:employee) { FactoryGirl.create(:employee,
      first_name: "Meg") }
    let(:profile) { FactoryGirl.create(:profile,
      employee: employee) }

    it "should take a dirty activerecord profile model and create an employee delta" do
      employee.assign_attributes(first_name: "Meghan")
      profile.assign_attributes(company: "OpenTable Mars Colony, Inc")
      new_delta = EmpDelta.build_from_profile(profile)
      expect(EmpDelta.count).to eq(0)
      expect(new_delta.before).to eq({"first_name"=>"Meg","company"=>"OpenTable, Inc."})
      expect(new_delta.after).to eq({"first_name"=>"Meghan","company"=>"OpenTable Mars Colony, Inc"})
      expect(new_delta.employee_id).to eq(employee.id)
    end
  end
end
