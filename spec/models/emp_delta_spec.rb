require 'rails_helper'

RSpec.describe EmpDelta, type: :model do
  let(:employee) { FactoryGirl.create(:employee)}
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
      old_mgr = FactoryGirl.create(:employee)
      new_mgr = FactoryGirl.create(:employee)
      old_loc = FactoryGirl.create(:location)
      new_loc = FactoryGirl.create(:location)
      old_jt = FactoryGirl.create(:job_title)
      new_jt = FactoryGirl.create(:job_title)
      delta = FactoryGirl.create(:emp_delta,
        before: {
          "location_id" => old_loc.id,
          "manager_id" => old_mgr.employee_id,
          "job_title_id" => old_jt.id},
        after: {
          "manager_id" => new_mgr.employee_id,
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
    end
  end
end
