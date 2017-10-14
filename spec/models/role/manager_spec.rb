require 'rails_helper'
require 'cancan/matchers'

describe Role::Manager, :type => :model do
  let(:manager)       { FactoryGirl.create(:employee) }
  let(:user)          { FactoryGirl.create(:user, :manager, employee: manager) }
  let(:direct_report) { FactoryGirl.create(:employee, manager: manager) }
  let(:employee)      { FactoryGirl.create(:employee) }
  let(:ability) { Ability.new(user) }

  describe 'abilities' do
    it_should_behave_like "role abilities", Employee, [:read, :autocomplete_email, :autocomplete_name]
    it_should_behave_like "role abilities", EmpTransaction, [:new, :show, :create]
    it_should_behave_like "role abilities", ManagerEntry, [:create]

    it "should only be able to read direct reports" do
      expect(ability).to be_able_to(:read, direct_report)
      expect(ability).to_not be_able_to(:read, employee)
    end
  end
end
