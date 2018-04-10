require 'rails_helper'

describe AuditService, type: :service do

  let!(:json)         { File.read(Rails.root.to_s + '/spec/fixtures/adp_termed_worker.json') }
  let(:audit_service) { AuditService.new }
  let(:adp_service)   { double(AdpService::Base) }
  let(:ad)            { double(ActiveDirectoryService) }
  let!(:manager)      { FactoryGirl.create(:employee) }
  let!(:employee)     { FactoryGirl.create(:active_employee, manager: manager) }

  let!(:regular_termination) do
    FactoryGirl.create(:terminated_employee,
      first_name: 'Diane',
      last_name: 'Sawyer',
      termination_date: 1.week.ago,
      offboarded_at: 1.week.ago,
      sam_account_name: 'dsawyer',
      manager: manager)
  end
  let!(:missed_deactivation) do
    FactoryGirl.create(:terminated_employee,
      first_name: 'Tom',
      last_name: 'Brokaw',
      sam_account_name: 'tbrowkow',
      termination_date: 3.days.ago,
      offboarded_at: 3.days.ago,
      manager: manager,
      adp_status: 'Terminated')
  end
  let!(:missed_offboard) do
    FactoryGirl.create(:active_employee,
      last_name: 'A',
      status: 'active',
      adp_status: 'Active',
      termination_date: 1.day.ago,
      manager: manager)
  end
  let!(:missed_offboard_2) do
    FactoryGirl.create(:active_employee,
      last_name: 'B',
      termination_date: Date.today,
      manager: manager,
      status: 'active',
      adp_status: 'Terminated')
  end
  let!(:missed_offboard_3) do
    FactoryGirl.create(:terminated_employee,
      last_name: 'C',
      termination_date: Date.yesterday,
      sam_account_name: 'cc',
      offboarded_at: nil,
      manager: manager,
      adp_status: 'Terminated')
  end
  let!(:missed_termination) do
    FactoryGirl.create(:active_employee, :existing,
      last_name: 'D',
      updated_at: 3.days.ago,
      termination_date: nil,
      manager: manager)
  end
  let!(:missed_contract_end) do
    FactoryGirl.create(:active_employee,
      last_name: 'E',
      contract_end_date: 1.week.ago,
      manager: manager)
  end

  describe '#missed_terminations' do
    subject(:audit) { audit_service.missed_terminations }

    let(:csv) { audit_service.generate_csv(audit) }
    let(:term_csv) do
      <<-EOS.strip_heredoc
      name,job_title,department,location,manager,status,adp_status,term_date,contract_end_date,offboarded_at,current_adp_status,adp_term_date
      #{missed_offboard.cn},#{missed_offboard.job_title.name},#{missed_offboard.department.name},#{missed_offboard.location.name},#{missed_offboard.manager.cn},active,Active,#{missed_offboard.termination_date.strftime('%Y-%m-%d')},"","",Terminated,2017-06-01
      #{missed_offboard_2.cn},#{missed_offboard_2.job_title.name},#{missed_offboard_2.department.name},#{missed_offboard_2.location.name},#{missed_offboard_2.manager.cn},active,Terminated,#{missed_offboard_2.termination_date.strftime('%Y-%m-%d')},"","",Terminated,2017-06-01
      #{missed_offboard_3.cn},#{missed_offboard_3.job_title.name},#{missed_offboard_3.department.name},#{missed_offboard_3.location.name},#{missed_offboard_3.manager.cn},terminated,Terminated,#{Date.yesterday.strftime('%Y-%m-%d')},"","",Terminated,2017-06-01
      #{missed_termination.cn},#{missed_termination.job_title.name},#{missed_termination.department.name},#{missed_termination.location.name},#{missed_termination.manager.cn},active,,"","","",Terminated,2017-06-01
      #{missed_contract_end.cn},#{missed_contract_end.job_title.name},#{missed_contract_end.department.name},#{missed_contract_end.location.name},#{missed_contract_end.manager.cn},active,,"",#{missed_contract_end.contract_end_date.strftime('%Y-%m-%d')},"",Terminated,2017-06-01
      EOS
    end

    before do
      allow(adp_service).to receive(:worker).and_return(JSON.parse(json))
      allow(AdpService::Base).to receive(:new).and_return(adp_service)
      allow(ActiveDirectoryService).to receive(:new).and_return(ad)
    end

    it 'has all the missed terminations' do
      expect(audit.length).to eq(5)
    end

    it 'checks the adp status' do
      audit_service.missed_terminations
      expect(adp_service).to have_received(:worker).exactly(5).times
    end

    it 'gets the adp status' do
      expect(audit.any? { |hash| hash[:adp_status] == 'Terminated' }).to eq(true)
    end

    it "should output csv string for missed offboards" do
      expect(csv).to eq(term_csv)
    end
  end

  describe '#missed_deactivation' do
    subject(:audit) { audit_service.missed_deactivations }

    let(:csv) { audit_service.generate_csv(audit) }

    let(:disabled_ldap_entry) do
      [{ :dn=>["CN=Diane Sawyer,OU=Disabled Users,OU=OT,DC=ottest,DC=opentable,DC=com"],
         :useraccountcontrol=>["514"]}]
    end

    let(:disabled_ldap_entry_2) do
      [{ :dn=>["CN=#{missed_offboard_3.cn},OU=IT,OU=Users,OU=OT,DC=ottest,DC=opentable,DC=com"],
         :useraccountcontrol=>["514"]}]
    end

    let(:enabled_ldap_entry) do
      [{ :dn=>["CN=Tom Browkaw,OU=IT,OU=Users,OU=OT,DC=ottest,DC=opentable,DC=com"],
         :useraccountcontrol=>["512"]}]
    end

    let(:ad_csv) do
      <<-EOS.strip_heredoc
      name,job_title,department,location,manager,status,adp_status,term_date,contract_end_date,offboarded_at,ldap_dn
      #{missed_deactivation.cn},#{missed_deactivation.job_title.name},#{missed_deactivation.department.name},#{missed_deactivation.location.name},#{missed_deactivation.manager.cn},terminated,Terminated,#{missed_deactivation.termination_date.strftime('%Y-%m-%d')},"",#{missed_deactivation.offboarded_at.strftime('%Y-%m-%d')},"cn=tom browkaw,ou=it,ou=users,ou=ot,dc=ottest,dc=opentable,dc=com"
      #{missed_offboard_3.cn},#{missed_offboard_3.job_title.name},#{missed_offboard_3.department.name},#{missed_offboard_3.location.name},#{missed_offboard_3.manager.cn},terminated,Terminated,#{missed_offboard_3.termination_date.strftime('%Y-%m-%d')},"","","cn=#{missed_offboard_3.cn.downcase},ou=it,ou=users,ou=ot,dc=ottest,dc=opentable,dc=com"
      EOS
    end

    before do
      allow(ActiveDirectoryService).to receive(:new).and_return(ad)
      allow(ad).to receive(:find_entry).with("sAMAccountName", regular_termination.sam_account_name).and_return(disabled_ldap_entry)
      allow(ad).to receive(:find_entry).with("sAMAccountName", missed_offboard_3.sam_account_name).and_return(disabled_ldap_entry_2)
      allow(ad).to receive(:find_entry).with("sAMAccountName", missed_deactivation.sam_account_name).and_return(enabled_ldap_entry)
      audit_service.missed_deactivations
    end

    it 'checks AD deactivation for each terminated worker' do
      expect(ad).to have_received(:find_entry).with("sAMAccountName", regular_termination.sam_account_name)
      expect(ad).to have_received(:find_entry).with("sAMAccountName", missed_deactivation.sam_account_name)
      expect(ad).to have_received(:find_entry).with("sAMAccountName", missed_offboard_3.sam_account_name)
    end

    it 'outputs csv with missed deactivation' do
      expect(csv).to eq(ad_csv)
    end
  end
end
