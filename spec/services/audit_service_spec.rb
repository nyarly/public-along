require 'rails_helper'

describe AuditService, type: :service do

  let(:audit_service) { AuditService.new }
  let(:adp_service) { double(AdpService::Base) }
  let(:ad_service) { double(ActiveDirectoryService) }

  let!(:manager) { FactoryGirl.create(:employee) }
  let!(:manager_prof) { FactoryGirl.create(:profile,
    employee: manager) }
  let!(:regular_employee) { FactoryGirl.create(:active_employee) }
  let!(:profile) { FactoryGirl.create(:active_profile,
    employee: regular_employee,
    manager_id: manager.employee_id) }
  let!(:regular_termination) { FactoryGirl.create(:terminated_employee,
    first_name: "Diane",
    last_name: "Sawyer",
    termination_date: 1.week.ago,
    sam_account_name: "dsawyer") }
  let!(:reg_term_prof) { FactoryGirl.create(:terminated_profile,
    employee: regular_termination,
    manager_id: manager.employee_id) }
  let!(:missed_deactivation) { FactoryGirl.create(:terminated_employee,
    first_name: "Tom",
    last_name: "Brokaw",
    sam_account_name: "tbrowkow",
    termination_date: 3.days.ago) }
  let!(:md_profile) { FactoryGirl.create(:terminated_profile,
    employee: missed_deactivation,
    manager_id: manager.employee_id) }
  let!(:missed_offboard) { FactoryGirl.create(:active_employee,
    termination_date: 4.days.ago) }
  let!(:m_o_profile) { FactoryGirl.create(:active_profile,
    employee: missed_offboard,
    manager_id: manager.employee_id) }
  let!(:missed_termination) { FactoryGirl.create(:active_employee, :existing,
    updated_at: 3.days.ago,
    termination_date: nil) }
  let!(:mt_profile) { FactoryGirl.create(:active_profile,
    employee: missed_termination,
    manager_id: manager.employee_id) }
  let!(:missed_contract_end) { FactoryGirl.create(:active_employee,
    contract_end_date: 1.week.ago) }
  let!(:mc_profile) { FactoryGirl.create(:active_profile,
    employee: missed_contract_end,
    manager_id: manager.employee_id) }
  let!(:terminated_worker_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_termed_worker.json")}

  before :each do
    allow(AdpService::Base).to receive(:new).and_return(adp_service)
    allow(ActiveDirectoryService).to receive(:new).and_return(ad_service)
  end

  context "checking for missed terminations" do
    let(:term_csv) {
      <<-EOS.strip_heredoc
      name,job_title,department,location,manager,mezzo_status,mezzo_term_date,contract_end_date,adp_status,adp_term_date
      #{missed_offboard.cn},#{missed_offboard.job_title.name},#{missed_offboard.department.name},#{missed_offboard.location.name},#{missed_offboard.manager.first_name} #{missed_offboard.manager.last_name},active,#{missed_offboard.termination_date.strftime('%Y-%m-%d')},"",Terminated,2017-06-01
      #{missed_termination.cn},#{missed_termination.job_title.name},#{missed_termination.department.name},#{missed_termination.location.name},#{missed_termination.manager.first_name} #{missed_termination.manager.last_name},active,"","",Terminated,2017-06-01
      #{missed_contract_end.cn},#{missed_contract_end.job_title.name},#{missed_contract_end.department.name},#{missed_contract_end.location.name},#{missed_contract_end.manager.first_name} #{missed_contract_end.manager.last_name},active,"",#{missed_contract_end.contract_end_date.strftime('%Y-%m-%d')},Terminated,2017-06-01
      EOS
    }

    it "should find the missed offboards" do
      allow(adp_service).to receive(:worker).and_return(JSON.parse(terminated_worker_json))
      missing_terminations = audit_service.missed_terminations

      expect(missing_terminations.length).to eq(3)
      expect(missing_terminations.any? { |hash| hash[:name] == "#{missed_termination.cn}"}).to eq(true)
      expect(missing_terminations.any? { |hash| hash[:name] == "#{missed_offboard.cn}"}).to eq(true)
      expect(missing_terminations.any? { |hash| hash[:name] == "#{missed_contract_end.cn}"}).to eq(true)
      expect(missing_terminations.any? { |hash| hash[:name] == "#{regular_termination.cn}"}).to eq(false)
      expect(missing_terminations.any? { |hash| hash[:name] == "#{regular_employee.cn}"}).to eq(false)
    end

    it "should check the adp status" do
      expect(adp_service).to receive(:worker).and_return(JSON.parse(terminated_worker_json)).thrice
      missing_terminations = audit_service.missed_terminations
      expect(missing_terminations.any? { |hash| hash[:adp_status] == "Terminated"}).to eq(true)
      expect(missing_terminations.any? { |hash| hash[:adp_term_date] == "2017-06-01"}).to eq(true)
    end

    it "should output csv string for missed offboards" do
      allow(adp_service).to receive(:worker).and_return(JSON.parse(terminated_worker_json))
      missed_terminations = audit_service.missed_terminations
      generated_csv = audit_service.generate_csv(missed_terminations)
      expect(generated_csv).to eq(term_csv)
    end
  end

  context "confirming AD deactivation for terminated users" do
    let(:disabled_ldap_entry) do [{
      :dn=>["CN=Diane Sawyer,OU=Disabled Users,OU=Users,OU=OT,DC=ottest,DC=opentable,DC=com"],
      :useraccountcontrol=>["514"]}] end
    let(:enabled_ldap_entry) do [{
      :dn=>["CN=Tom Browkaw,OU=IT,OU=Users,OU=OT,DC=ottest,DC=opentable,DC=com"],
      :useraccountcontrol=>["512"]}] end
    let(:ad_csv) {
      <<-EOS.strip_heredoc
      name,job_title,department,location,manager,mezzo_status,mezzo_term_date,contract_end_date,ldap_dn
      #{missed_deactivation.cn},#{missed_deactivation.job_title.name},#{missed_deactivation.department.name},#{missed_deactivation.location.name},#{missed_deactivation.manager.first_name} #{missed_deactivation.manager.last_name},terminated,#{missed_deactivation.termination_date.strftime('%Y-%m-%d')},"","cn=tom browkaw,ou=it,ou=users,ou=ot,dc=ottest,dc=opentable,dc=com"
      EOS
    }

    it "should should check all terminated users" do
      expect(ad_service).to receive(:find_entry).with("sAMAccountName", regular_termination.sam_account_name).and_return(disabled_ldap_entry)
      expect(ad_service).to receive(:find_entry).with("sAMAccountName", missed_deactivation.sam_account_name).and_return(enabled_ldap_entry)
      missed_deactivations = audit_service.ad_deactivation
      expect(missed_deactivations.length).to eq(1)
      expect(missed_deactivations.any? { |hash| hash[:name] == "#{missed_deactivation.cn}"}).to eq(true)
      expect(missed_deactivations.any? { |hash| hash[:name] == "#{regular_termination.cn}"}).to eq(false)
    end

    it "should output csv string for missed AD deactivations" do
      expect(ad_service).to receive(:find_entry).with("sAMAccountName", regular_termination.sam_account_name).and_return(disabled_ldap_entry)
      expect(ad_service).to receive(:find_entry).with("sAMAccountName", missed_deactivation.sam_account_name).and_return(enabled_ldap_entry)
      missed_ad_deactivations = audit_service.ad_deactivation
      generated_csv = audit_service.generate_csv(missed_ad_deactivations)
      expect(generated_csv).to eq(ad_csv)
    end
  end
end
