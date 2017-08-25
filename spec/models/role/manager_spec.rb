require 'rails_helper'
require 'cancan/matchers'

describe Role::Manager, :type => :model do
  let(:user) { FactoryGirl.create(:user, :manager) }
  let(:direct_report) { FactoryGirl.create(:employee) }
  let!(:dr_profile) { FactoryGirl.create(:profile,
    employee: direct_report,
    manager_id: user.employee_id)}
  let(:employee) { FactoryGirl.create(:employee) }
  let!(:emp_profile) { FactoryGirl.create(:profile,
    employee: employee,
    manager_id: "nonsense")}
  let(:ability) { Ability.new(user) }

  describe 'abilities' do
    it_should_behave_like "role abilities", Employee, [:read, :create, :update, :autocomplete_email, :autocomplete_name]
    it_should_behave_like "role abilities", EmpTransaction, [:new, :show, :create]
    it_should_behave_like "role abilities", ManagerEntry, [:create]
    it_should_behave_like "role abilities", Profile, [:create]

    it "should only be able to read direct reports" do
      expect(ability).to be_able_to(:read, direct_report)
      expect(ability).to_not be_able_to(:read, employee)
    end
  end
end
