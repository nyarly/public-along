require 'rails_helper'

RSpec.describe EmpTransaction, type: :model do
  let(:emp_transaction) { FactoryGirl.build(:emp_transaction) }

  it "should meet validations" do
  expect(emp_transaction).to be_valid

  expect(emp_transaction).to_not allow_value(nil).for(:user_id)
  expect(emp_transaction).to_not allow_value(nil).for(:kind)
  expect(emp_transaction).to_not allow_value(nil).for(:employee_id)
  end
end
