require 'rails_helper'

describe OnboardQuery, type: :query do
  let(:parent_org_a)    { FactoryGirl.create(:parent_org, name: "Aaa") }
  let(:parent_org_b)    { FactoryGirl.create(:parent_org, name: "Bbb") }

  let(:dept_c)          { FactoryGirl.create(:department,
                          name: "Ccc",
                          parent_org: parent_org_a) }
  let(:dept_d)          { FactoryGirl.create(:department,
                          name: "Ddd",
                          parent_org: parent_org_b) }
  let(:dept_e)          { FactoryGirl.create(:department,
                          name: "Eee",
                          parent_org: parent_org_b) }

  let(:new_emp_1)       { FactoryGirl.create(:employee,
                          hire_date: 4.days.ago,
                          status: "active") }
  let!(:new_emp_1_p)    { FactoryGirl.create(:profile,
                          profile_status: "active",
                          start_date: 4.days.ago,
                          employee: new_emp_1,
                          department: dept_e) }
  let(:new_emp_2)       { FactoryGirl.create(:employee,
                          hire_date: 4.days.ago,
                          status: "active") }
  let!(:new_emp_2_p)    { FactoryGirl.create(:profile,
                          profile_status: "active",
                          start_date: 4.days.ago,
                          employee: new_emp_2,
                          department: dept_c) }

  let(:new_hire_1)      { FactoryGirl.create(:employee,
                          status: "pending",
                          hire_date: 3.days.from_now) }
  let!(:new_hire_1_p)   { FactoryGirl.create(:profile,
                          employee: new_hire_1,
                          start_date: 3.days.from_now,
                          profile_status: "pending",
                          department: dept_e) }
  let(:new_hire_2)      { FactoryGirl.create(:employee,
                          last_name: "Aaa",
                          status: "pending",
                          hire_date: 1.week.from_now) }
  let!(:new_hire_2_p)   { FactoryGirl.create(:profile,
                          employee: new_hire_2,
                          profile_status: "pending",
                          start_date: 1.week.from_now,
                          department: dept_c) }
  let(:new_hire_3)      { FactoryGirl.create(:employee,
                          last_name: "Aaa",
                          status: "pending",
                          hire_date: 1.week.from_now) }
  let!(:new_hire_3_p)   { FactoryGirl.create(:profile,
                          employee: new_hire_3,
                          profile_status: "pending",
                          start_date: 1.week.from_now,
                          department: dept_d) }
  let(:rehire)          { FactoryGirl.create(:employee,
                          last_name: "Bbb",
                          status: "pending",
                          hire_date: 1.year.ago) }
  let!(:rehire_p)       { FactoryGirl.create(:profile,
                          employee: rehire,
                          profile_status: "pending",
                          start_date: 4.days.from_now,
                          department: dept_c) }
  let!(:rehire_p_2)    { FactoryGirl.create(:profile,
                          employee: rehire,
                          profile_status: "terminated",
                          start_date: 1.year.ago) }
  let(:conversion)      { FactoryGirl.create(:employee,
                          last_name: "Bbb",
                          status: "active",
                          start_date: 6.months.ago) }
  let!(:conversion_p)   { FactoryGirl.create(:profile,
                          profile_status: "pending",
                          start_date: 4.days.from_now,
                          department: dept_d) }
  let!(:conversion_p_2) { FactoryGirl.create(:profile,
                          profile_status: "active",
                          start_date: 6.months.ago,
                          end_date: 3.days.from_now,
                          department: dept_e) }

  it "should get the pending orders in the correct order" do
    query = OnboardQuery.new(:onboarding).all
    expect(query).to eq([new_hire_2_p, rehire_p, new_hire_3_p, conversion_p, new_hire_1_p])
  end

  it "should get the workers who started in the last week in the correct order" do
    query = OnboardQuery.new(:onboarded_this_week).all
    expect(query).to eq([new_emp_2_p, new_emp_1_p])
  end
end
