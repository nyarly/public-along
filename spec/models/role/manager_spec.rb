require 'rails_helper'
require 'cancan/matchers'

describe Role::Manager, :type => :model do
  let :user do FactoryGirl.create(:user, :manager) end
  let :direct_report do FactoryGirl.create(:employee, manager_id: user.employee_id) end
  let :employee do FactoryGirl.create(:employee, manager_id: "someone else") end
  let :ability do Ability.new(user) end

  describe 'abilities' do
    it_should_behave_like "role abilities", Employee, [:read, :autocomplete_name]
    it_should_behave_like "role abilities", EmpTransaction, [:new, :show, :create]
    it_should_behave_like "role abilities", ManagerEntry, [:create]

    it "should only be able to read direct reports" do
      expect(ability).to be_able_to(:read, direct_report)
      expect(ability).to_not be_able_to(:read, employee)
    end
  end
end
