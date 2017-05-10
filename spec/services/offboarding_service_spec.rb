require 'rails_helper'

describe OffboardingService, type: :service do
  let!(:manager) { FactoryGirl.create(:employee) }
  let!(:employee) { FactoryGirl.create(:employee, manager_id: manager.id, termination_date: Date.new(2017, 6, 1)) }
  let!(:security_profile) { FactoryGirl.create(:security_profile) }
  let!(:application) { FactoryGirl.create(:application, name: "Google Apps") }
  let!(:access_level) { FactoryGirl.create(:access_level, application_id: application.id) }
  let!(:sec_prof_access_level) {
    FactoryGirl.create(:sec_prof_access_level,
       security_profile_id: security_profile.id,
       access_level_id: access_level.id)}
  let!(:emp_transaction) { FactoryGirl.create(:emp_transaction, kind: "Onboarding") }
  let!(:emp_sec_profile) {
    FactoryGirl.create(:emp_sec_profile,
      emp_transaction_id: emp_transaction.id,
      employee_id: employee.id,
      security_profile_id: security_profile.id)}

  Timecop.freeze(Time.new(2017, 6, 01, 15, 30, 0, "+00:00"))

  context "without emp access levels" do
    it "should successfully create and return emp access levels" do
      expect{
        OffboardingService.new([employee])
      }.to change{employee.emp_access_levels.count}.from(0).to(1)
      expect(employee.emp_access_levels[0].access_level_id).to eq(access_level.id)
      expect(employee.emp_access_levels[0].employee_id).to eq(employee.id)
      expect(employee.emp_access_levels[0].active).to eq(true)
    end
  end

  context "with an existing emp acess level" do
    let!(:emp_access_level) {
      FactoryGirl.create(:emp_access_level,
        employee_id: employee.id,
        access_level_id: access_level.id,
        active: true)}


    it "should use submitted offboarding info" do
      expect{
        OffboardingService.new([employee])
      }.not_to change{employee.emp_access_levels.count}
      expect(employee.emp_access_levels[0].access_level_id).to eq(access_level.id)
      expect(employee.emp_access_levels[0].employee_id).to eq(employee.id)
      expect(employee.emp_access_levels[0].active).to eq(true)
    end
  end
end
