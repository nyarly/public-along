require 'rails_helper'

describe SecAccessService, type: :service do
  let(:ldap)                       { double(Net::LDAP) }
  let!(:employee)                   { FactoryGirl.create(:regular_employee) }
  let!(:emp_transaction)            { FactoryGirl.create(:emp_transaction,
                                                        employee_id: employee.id) }
  let!(:emp_transaction_old)        { FactoryGirl.create(:emp_transaction,
                                                        employee_id: employee.id) }
  let!(:emp_sec_profile)           { FactoryGirl.create(:emp_sec_profile,
                                                        security_profile_id: sec_prof.id,
                                                        emp_transaction_id: emp_transaction.id) }
  let!(:emp_sec_profile_old)       { FactoryGirl.create(:emp_sec_profile,
                                                        security_profile_id: sec_prof_old.id,
                                                        emp_transaction_id: emp_transaction_old.id,
                                                        revoking_transaction_id: emp_transaction.id) }
  let!(:sec_prof)                   { FactoryGirl.create(:security_profile) }
  let!(:sec_prof_old)               { FactoryGirl.create(:security_profile) }
  let!(:sec_prof_access_level)     { FactoryGirl.create(:sec_prof_access_level,
                                                        security_profile_id: sec_prof.id,
                                                        access_level_id: access_lvl.id) }
  let!(:sec_prof_access_level_old) { FactoryGirl.create(:sec_prof_access_level,
                                                        security_profile_id: sec_prof_old.id,
                                                        access_level_id: access_lvl_old.id) }
  let!(:access_lvl)                 { FactoryGirl.create(:access_level,
                                                        ad_security_group: "sec_dn",
                                                        application_id: app.id) }
  let!(:access_lvl_old)             { FactoryGirl.create(:access_level,
                                                        ad_security_group: "old_sec_dn",
                                                        application_id: app.id) }
  let(:app)                        { FactoryGirl.create(:application) }
  let(:sas)                        { SecAccessService.new(emp_transaction) }

  before :each do
    allow(Net::LDAP).to receive(:new).and_return(ldap)
    allow(ldap).to receive(:host=)
    allow(ldap).to receive(:port=)
    allow(ldap).to receive(:encryption)
    allow(ldap).to receive(:auth)
    allow(ldap).to receive(:bind)
    allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)
  end

  it "should add/remove worker to/from correct AD security groups" do
    expect(ldap).to receive(:modify).with(:dn => "sec_dn", :operations => [[:add, :member, employee.dn]])
    expect(ldap).to receive(:modify).with(:dn => "old_sec_dn", :operations => [[:delete, :member, employee.dn]])

    sas.apply_ad_permissions
  end
end
