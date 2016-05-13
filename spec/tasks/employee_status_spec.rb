require 'rails_helper'
require 'rake'

describe "employee:change_status" do

  context "employee:change_status" do
    before :each do
      Rake.application = Rake::Application.new
      Rake.application.rake_require "lib/tasks/employee_status", [Rails.root.to_s], ''
      Rake::Task.define_task :environment

      @ldap = double(Net::LDAP)

      allow(Net::LDAP).to receive(:new).and_return(@ldap)
      allow(@ldap).to receive(:host=)
      allow(@ldap).to receive(:port=)
      allow(@ldap).to receive(:encryption)
      allow(@ldap).to receive(:auth)
      allow(@ldap).to receive(:bind)
    end

    after :each do
      Timecop.return
    end

    it "should call ldap and update only GB new hires at 3am BST" do
      new_hire_uk = FactoryGirl.create(:employee, :hire_date => Date.new(2016, 7, 29), :country => 'GB')

      new_hire_us = FactoryGirl.create(:employee, :hire_date => Date.new(2016, 7, 29), :country => 'US')
      termination = FactoryGirl.create(:employee, :contract_end_date => Date.new(2016, 7, 29), :country => 'GB')

      # 7/29/2016 at 3am BST/2am UTC
      Timecop.freeze(Time.new(2016, 7, 29, 2, 0, 0, "+00:00"))

      expect(@ldap).to receive(:replace_attribute).once.with(
        new_hire_uk.dn, :userAccountControl, "512"
      )
      expect(@ldap).to_not receive(:replace_attribute).with(
        new_hire_us.dn, :userAccountControl, "512"
      )
      expect(@ldap).to_not receive(:replace_attribute).with(
        termination.dn, :userAccountControl, "514"
      )

      allow(@ldap).to receive(:get_operation_result)
      Rake::Task["employee:change_status"].invoke
    end

    it "should call ldap and update only US new hires at 3am PST" do
      new_hire_us = FactoryGirl.create(:employee, :hire_date => Date.new(2016, 7, 29), :country => 'US')
      new_hire_uk = FactoryGirl.create(:employee, :hire_date => Date.new(2016, 7, 29), :country => 'GB')
      termination = FactoryGirl.create(:employee, :contract_end_date => Date.new(2016, 7, 29), :country => 'US')

      # 7/29/2016 at 3am PST/10am UTC
      Timecop.freeze(Time.new(2016, 7, 29, 10, 0, 0, "+00:00"))

      expect(@ldap).to receive(:replace_attribute).once.with(
        new_hire_us.dn, :userAccountControl, "512"
      )
      expect(@ldap).to_not receive(:replace_attribute).with(
        new_hire_uk.dn, :userAccountControl, "512"
      )
      expect(@ldap).to_not receive(:replace_attribute).with(
        termination.dn, :userAccountControl, "514"
      )

      allow(@ldap).to receive(:get_operation_result)
      Rake::Task["employee:change_status"].invoke
    end

    it "should call ldap and update only terminations at 9pm in IST" do
      termination = FactoryGirl.create(:employee, :hire_date => Date.new(2014, 5, 3), :contract_end_date => Date.new(2016, 7, 29), :country => 'IN')
      new_hire_in = FactoryGirl.create(:employee, :hire_date => Date.new(2016, 7, 29), :country => 'IN')
      new_hire_us = FactoryGirl.create(:employee, :hire_date => Date.new(2016, 7, 29), :country => 'US')

      # 7/29/2016 at 9pm IST/3:30pm UTC
      Timecop.freeze(Time.new(2016, 7, 29, 15, 30, 0, "+00:00"))

      expect(@ldap).to receive(:replace_attribute).once.with(
        termination.dn, :userAccountControl, "514"
      )
      expect(@ldap).to_not receive(:replace_attribute).with(
        new_hire_us.dn, :userAccountControl, "512"
      )
      expect(@ldap).to_not receive(:replace_attribute).with(
        new_hire_in.dn, :userAccountControl, "512"
      )

      allow(@ldap).to receive(:get_operation_result)
      Rake::Task["employee:change_status"].invoke
    end
  end
end
