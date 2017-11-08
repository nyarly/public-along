require 'rails_helper'

describe SecAccessService, type: :service do
  let(:ldap)                   { double(Net::LDAP) }
  let(:employee)               { FactoryGirl.create(:regular_employee) }
  let!(:profile)               { FactoryGirl.create(:profile, :with_valid_ou, employee: employee) }
  let(:emp_trans_no_sec_prof)  { FactoryGirl.create(:emp_transaction, employee_id: employee.id) }
  let(:emp_transaction)        { FactoryGirl.create(:emp_transaction,
                                                    employee_id: employee.id) }
  let!(:emp_transaction_old)   { FactoryGirl.create(:emp_transaction,
                                                    employee_id: employee.id) }
  let!(:emp_sec_profile)       { FactoryGirl.create(:emp_sec_profile,
                                                    security_profile_id: sec_prof.id,
                                                    emp_transaction_id: emp_transaction.id) }
  let!(:emp_sec_profile_old)   { FactoryGirl.create(:emp_sec_profile,
                                                    security_profile_id: sec_prof_old.id,
                                                    emp_transaction_id: emp_transaction_old.id,
                                                    revoking_transaction_id: emp_transaction.id) }
  let!(:sec_prof)              { FactoryGirl.create(:security_profile) }
  let!(:sec_prof_old)          { FactoryGirl.create(:security_profile) }
  let!(:sec_prof_access_level) { FactoryGirl.create(:sec_prof_access_level,
                                                    security_profile_id: sec_prof.id,
                                                    access_level_id: access_lvl.id) }
  let!(:sp_al_old)             { FactoryGirl.create(:sec_prof_access_level,
                                                    security_profile_id: sec_prof_old.id,
                                                    access_level_id: access_lvl_old.id) }
  let(:access_lvl)             { FactoryGirl.create(:access_level,
                                                    ad_security_group: "sample new sec_dn",
                                                    application_id: app.id) }
  let(:access_lvl_old)         { FactoryGirl.create(:access_level,
                                                    ad_security_group: "sample old sec_dn",
                                                    application_id: app.id) }
  let(:access_lvl_blank)       { FactoryGirl.create(:access_level,
                                                    application_id: app.id) }
  let(:app)                    { FactoryGirl.create(:application) }
  let(:sas)                    { SecAccessService.new(emp_transaction) }
  let(:mailer)                 { double(TechTableMailer) }

  context "success" do
    before :each do
      allow(Net::LDAP).to receive(:new).and_return(ldap)
      allow(ldap).to receive(:host=)
      allow(ldap).to receive(:port=)
      allow(ldap).to receive(:encryption)
      allow(ldap).to receive(:auth)
      allow(ldap).to receive(:bind)
      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)
      allow(ldap).to receive_message_chain(:get_operation_result, :message).and_return("message")
    end

    it "should add/remove worker to/from correct AD security groups" do
      expect(ldap).to receive(:modify).with(:dn => "sample new sec_dn", :operations => [[:add, :member, employee.dn]])
      expect(ldap).to receive(:modify).with(:dn => "sample old sec_dn", :operations => [[:delete, :member, employee.dn]])
      expect(ldap).not_to receive(:modify).with(:dn => nil, :operations => [[:delete, :member, employee.dn]])

      sas.apply_ad_permissions
    end

    it "should create a hash with the expected results" do
      expect(ldap).to receive(:modify).with(:dn => "sample new sec_dn", :operations => [[:add, :member, employee.dn]])
      expect(ldap).to receive(:modify).with(:dn => "sample old sec_dn", :operations => [[:delete, :member, employee.dn]])

      sas.apply_ad_permissions

      expect(sas.results).to eq(
        [{:dn=>"#{employee.dn}", :sec_dn=>"sample new sec_dn", :action=>"add", :status=>"success", :code=>0, :message=>"message"},
         {:dn=>"#{employee.dn}", :sec_dn=>"sample old sec_dn", :action=>"delete", :status=>"success", :code=>0, :message=>"message"}]
        )
      expect(sas.failures).to eq([])
    end
  end

  context "failure" do
    let(:failure_ldap_response) { OpenStruct.new(code: 53, message: "Unwilling to perform") }

    before :each do
      allow(Net::LDAP).to receive(:new).and_return(ldap)
      allow(ldap).to receive(:host=)
      allow(ldap).to receive(:port=)
      allow(ldap).to receive(:encryption)
      allow(ldap).to receive(:auth)
      allow(ldap).to receive(:bind)
      allow(ldap).to receive_message_chain(:get_operation_result).and_return(failure_ldap_response)
    end

    it "should create a hash with the exected results" do
      expect(ldap).to receive(:modify).with(:dn => "sample new sec_dn", :operations => [[:add, :member, employee.dn]])
      expect(ldap).to receive(:modify).with(:dn => "sample old sec_dn", :operations => [[:delete, :member, employee.dn]])

      sas.apply_ad_permissions

      expect(sas.results).to eq(
        [{:dn=>"#{employee.dn}", :sec_dn=>"sample new sec_dn", :action=>"add", :status=>"failure", :code=>53, :message=>"Unwilling to perform"},
         {:dn=>"#{employee.dn}", :sec_dn=>"sample old sec_dn", :action=>"delete", :status=>"failure", :code=>53, :message=>"Unwilling to perform"}]
        )
      expect(sas.failures).to eq(
        [{:dn=>"#{employee.dn}", :sec_dn=>"sample new sec_dn", :action=>"add", :status=>"failure", :code=>53, :message=>"Unwilling to perform"},
         {:dn=>"#{employee.dn}", :sec_dn=>"sample old sec_dn", :action=>"delete", :status=>"failure", :code=>53, :message=>"Unwilling to perform"}]
        )
    end

    it "should send an alert email on failure" do
      subject = "Failed Security Access Change for #{employee.cn}"
      message = "Mezzo received a request to add and/or remove #{employee.cn} from security groups in Active Directory. One or more of these transactions have failed."
      failure_data = [{:dn=>"#{employee.dn}", :sec_dn=>"sample new sec_dn", :action=>"add", :status=>"failure", :code=>53, :message=>"Unwilling to perform"},
                      {:dn=>"#{employee.dn}", :sec_dn=>"sample old sec_dn", :action=>"delete", :status=>"failure", :code=>53, :message=>"Unwilling to perform"}]

      expect(ldap).to receive(:modify).twice
      expect(TechTableMailer).to receive(:alert).with(subject, message, failure_data).and_return(mailer)
      expect(mailer).to receive(:deliver_now)

      sas.apply_ad_permissions

      expect(sas.results).to eq(failure_data)
      expect(sas.failures).to eq(failure_data)
    end
  end
end
