require 'rails_helper'

describe ActiveDirectoryService, type: :service do
  let(:ldap) { double(Net::LDAP) }
  let(:ads) { ActiveDirectoryService.new }

  let(:department) { Department.find_or_create_by(:name => "People & Culture-HR & Total Rewards") }
  let(:location) { Location.find_or_create_by(:name => "San Francisco Headquarters") }
      let!(:job_title) { FactoryGirl.create(:job_title) }
    let!(:new_job_title) { FactoryGirl.create(:job_title) }
  let(:manager) { FactoryGirl.create(:employee) }
  let!(:manager_profile) { FactoryGirl.create(:profile,
    :with_valid_ou,
    employee: manager)}

  before :each do
    allow(Net::LDAP).to receive(:new).and_return(ldap)
    allow(ldap).to receive(:host=)
    allow(ldap).to receive(:port=)
    allow(ldap).to receive(:encryption)
    allow(ldap).to receive(:auth)
    allow(ldap).to receive(:bind)

    Timecop.freeze(Time.now)
  end

  after :each do
    Timecop.return
  end

  context "create disabled employees" do
    let!(:employee) { FactoryGirl.create(:employee,
      first_name: "Donny",
      last_name: "Kerabatsos") }
    let!(:profile) { FactoryGirl.create(:profile,
      :with_valid_ou,
      employee: employee,
      manager_id: manager.employee_id)}

    it "should call ldap.add with correct info for regular employee" do
      allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName
      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)

      expect(ldap).to receive(:add).once.with(
        hash_including(
          :dn => employee.dn,
          attributes: employee.ad_attrs.merge({
            :sAMAccountName => "dkerabatsos",
            :mail => "dkerabatsos@opentable.com",
            :userPrincipalName => "dkerabatsos@opentable.com"
          }).delete_if { |k,v| v.blank? || k == :dn}
        )
      )

      ads.create_disabled_accounts([employee])
      expect(employee.sam_account_name).to eq("dkerabatsos")
      expect(employee.email).to eq("dkerabatsos@opentable.com")
      expect(employee.ad_updated_at).to eq(DateTime.now)
    end

    it "should eventually call ldap.add with a generated numeric sAMAccountName" do
      allow(ldap).to receive(:search).and_return("entry", "entry", "entry", []) # Mock search finding conflicting sAMAccountNames
      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)

      expect(ldap).to receive(:add)

      ads.create_disabled_accounts([employee])
      expect(employee.sam_account_name).to eq("dkerabatsos1")
      expect(employee.email).to eq("dkerabatsos1@opentable.com")
      expect(employee.ad_updated_at).to eq(DateTime.now)
    end

    it "should set errors when account creation fails" do
      allow(ldap).to receive(:add)
      allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName
      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(67) # Simulate AD LDAP error

      ads.create_disabled_accounts([employee])

      expect(ads.errors).to eq({active_directory: "Creation of disabled account for Donny Kerabatsos failed. Check the record for errors and re-submit."})
    end
  end

  context "activate employees" do
    let(:mailer) { double(TechTableMailer) }

    it "should fail and send alert email if it is a contract worker and there is no contract end date set" do
      invalid_contract_worker = FactoryGirl.create(:contract_worker,
        contract_end_date: nil)
      emp_trans = FactoryGirl.create(:onboarding_emp_transaction,
       employee_id: invalid_contract_worker.id)
      sec_prof = FactoryGirl.create(:security_profile)
      emp_sec_prof = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans.id,
        security_profile_id: sec_prof.id)
      allow(invalid_contract_worker).to receive(:ou).and_return("ou=Valid OU")

      expect(TechTableMailer).to receive(:alert_email).once.and_return(mailer)
      expect(mailer).to receive(:deliver_now).once
      ads.activate([invalid_contract_worker])
    end

    it "should activate for properly set contract worker" do
      valid_contract_worker = FactoryGirl.create(:contract_worker)
      emp_trans = FactoryGirl.create(:onboarding_emp_transaction,
        employee_id: valid_contract_worker.id)
      onboarding_info = FactoryGirl.create(:onboarding_info,
        emp_transaction_id: emp_trans.id)
      sec_prof = FactoryGirl.create(:security_profile)
      emp_sec_prof = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans.id,
        security_profile_id: sec_prof.id)
      allow(valid_contract_worker).to receive(:ou).and_return("ou=Valid OU")

      allow(ldap).to receive(:replace_attribute).once
      expect(TechTableMailer).to_not receive(:alert_email).with("ERROR: #{valid_contract_worker.first_name} #{valid_contract_worker.last_name} is a contract worker and needs a contract_end_date. Account not activated.")
      ads.activate([valid_contract_worker])
    end

    it "should activate for properly set contract worker with no security profiles" do
      valid_contract_worker = FactoryGirl.create(:contract_worker)
      emp_trans = FactoryGirl.create(:onboarding_emp_transaction,
        employee_id: valid_contract_worker.id)
      onboarding_info = FactoryGirl.create(:onboarding_info,
        emp_transaction_id: emp_trans.id)
      allow(valid_contract_worker).to receive(:ou).and_return("ou=Valid OU")

      allow(ldap).to receive(:replace_attribute).once
      expect(TechTableMailer).to_not receive(:alert_email).with("ERROR: #{valid_contract_worker.first_name} #{valid_contract_worker.last_name} is a contract worker and needs a contract_end_date. Account not activated.")
      ads.activate([valid_contract_worker])
    end

    it "should fail if the manager has not completed the onboarding forms" do
      invalid_worker = FactoryGirl.create(:regular_employee)

      expect(TechTableMailer).to receive(:alert_email).once.and_return(mailer)
      expect(mailer).to receive(:deliver_now).once
      ads.activate([invalid_worker])
    end
  end

  context "assign sAMAccountName" do
    it "should normalize special characters and spaces" do
      employee = FactoryGirl.create(:employee,
        :first_name => "Mæby",
        :last_name => "Fünke Spløsh")

      allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName

      expect(ads.assign_sAMAccountName(employee)).to eq(true)
      expect(employee.sam_account_name).to eq("mfunkesplosh")
    end

    it "should return true when available sAMAccountName is found" do
      employee = FactoryGirl.create(:employee,
        :first_name => "Walter",
        :last_name => "Sobchak")

      allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName

      expect(ads.assign_sAMAccountName(employee)).to eq(true)
      expect(employee.sam_account_name).to eq("wsobchak")
    end

    it "should return false when no available sAMAccountName is found" do
      employee = FactoryGirl.create(:employee)

      allow(ldap).to receive(:search).and_return("entry") # Mock search finding conflicting existing sAMAccountName

      expect(ads.assign_sAMAccountName(employee)).to eq(false)
      expect(employee.sam_account_name).to eq(nil)
    end
  end

  context "update attributes" do
    let!(:worker_type) { FactoryGirl.create(:worker_type) }
    let!(:employee) { FactoryGirl.create(:employee,
      :first_name => "Jeffrey",
      :last_name => "Lebowski",
      :office_phone => "123-456-7890",
      :sam_account_name => "jlebowski")}
    let!(:profile) { FactoryGirl.create(:profile,
      employee: employee,
      profile_status: "Active",
      manager_id: manager.employee_id,
      department: department,
      location: location,
      job_title: job_title,
      adp_employee_id: "12345678")}

    let(:ldap_entry) { Net::LDAP::Entry.new(employee.dn) }

    before :each do
      ldap_entry[:cn] = "Jeffrey Lebowski"
      ldap_entry[:objectClass] = ["top", "person", "organizationalPerson", "user"]
      ldap_entry[:givenName] = "Jeffrey"
      ldap_entry[:sn] = "Lebowski"
      ldap_entry[:displayName] = "Jeffrey Lebowski"
      ldap_entry[:userPrincipalName] = "jlebowski@opentable.com"
      ldap_entry[:manager] = manager.dn
      ldap_entry[:co] = "US"
      ldap_entry[:accountExpires] = "9223372036854775807"
      ldap_entry[:title] = job_title.name,
      ldap_entry[:description] = job_title.name,
      ldap_entry[:employeeType] = worker_type.name,
      ldap_entry[:physicalDeliveryOfficeName] = "San Francisco Headquarters"
      ldap_entry[:department] = "People & Culture-HR & Total Rewards"
      ldap_entry[:employeeID] = "12345678"
      ldap_entry[:mobile] = "123-456-7890"
      ldap_entry[:telephoneNumber] = "123-456-7890"
      ldap_entry[:thumbnailPhoto] = employee.decode_img_code

      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)
    end

    it "should update changed attributes" do
      employee = FactoryGirl.create(:employee,
        :first_name => "The Dude",
        :last_name => "Lebowski",
        :office_phone => "555-555-5555",
        :sam_account_name => "jlebowski")
      profile = FactoryGirl.create(:profile,
        employee: employee,
        profile_status: "Active",
        manager_id: manager.employee_id,
        department: department,
        location: location,
        job_title: new_job_title,
        adp_employee_id: "12345678")

      allow(ldap).to receive(:search).and_return([ldap_entry])
      expect(ldap).to_not receive(:replace_attribute).with(employee.dn, :cn, "The Dude Lebowski")
      expect(ldap).to receive(:replace_attribute).once.with(employee.dn, :givenName, "The Dude")
      expect(ldap).to receive(:replace_attribute).once.with(employee.dn, :title, new_job_title.name)
      expect(ldap).to receive(:replace_attribute).once.with(employee.dn, :description, new_job_title.name)
      expect(ldap).to receive(:replace_attribute).once.with(employee.dn, :telephoneNumber, "555-555-5555")
      expect(ldap).to receive(:rename).once.with(
        :olddn => "cn=Jeffrey Lebowski,ou=People and Culture,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        :newrdn => "cn=The Dude Lebowski",
        :delete_attributes => true,
        :new_superior => "ou=People and Culture,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"
      )

      ads.update([employee])
      expect(employee.ad_updated_at).to eq(DateTime.now)
    end

    it "should update dn if country changes" do
      new_location = FactoryGirl.create(:location,
        name: location.name,
        country: "GB")
      employee = FactoryGirl.create(:employee,
        :first_name => "Jeffrey",
        :last_name => "Lebowski",
        :office_phone => "123-456-7890",
        :sam_account_name => "jlebowski")
      profile = FactoryGirl.create(:profile,
        employee: employee,
        profile_status: "Active",
        manager_id: manager.employee_id,
        department: department,
        location: new_location,
        job_title: job_title,
        adp_employee_id: "12345678")

      allow(ldap).to receive(:search).and_return([ldap_entry])

      expect(ldap).to receive(:replace_attribute).once.with(employee.dn, :co, "GB")
      expect(ldap).to receive(:rename).once.with(
        :olddn => "cn=Jeffrey Lebowski,ou=People and Culture,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        :newrdn => "cn=Jeffrey Lebowski",
        :delete_attributes => true,
        :new_superior => "ou=HR,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"
      )
      ads.update([employee])
      expect(employee.ad_updated_at).to eq(DateTime.now)
    end

    it "should update dn if department changes" do
      new_department = Department.find_by(:name => "Customer Support")
      employee = FactoryGirl.create(:employee,
        :first_name => "Jeffrey",
        :last_name => "Lebowski",
        :office_phone => "123-456-7890",
        :sam_account_name => "jlebowski")
      profile = FactoryGirl.create(:profile,
        employee: employee,
        profile_status: "Active",
        manager_id: manager.employee_id,
        department: new_department,
        job_title: job_title,
        adp_employee_id: "12345678",
        location: location)

      allow(ldap).to receive(:search).and_return([ldap_entry])

      expect(ldap).to receive(:replace_attribute).once.with(employee.dn, :department, "Customer Support")
      expect(ldap).to receive(:rename).once.with(
        :olddn => "cn=Jeffrey Lebowski,ou=People and Culture,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        :newrdn => "cn=Jeffrey Lebowski",
        :delete_attributes => true,
        :new_superior => "ou=Customer Support,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"
      )
      ads.update([employee])
      expect(employee.ad_updated_at).to eq(DateTime.now)
    end

    it "should not update unchanged attributes" do
      allow(ldap).to receive(:search).and_return([ldap_entry])

      expect(ldap).to_not receive(:replace_attribute)
      ads.update([employee])
      expect(employee.ad_updated_at).to be_nil
    end

    it "should send an alert email when account update fails" do
      employee.office_phone = "323-999-5555"
      allow(ldap).to receive(:search).and_return([ldap_entry])
      allow(ldap).to receive(:replace_attribute)
      # allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(67) # Simulate AD LDAP error

      # expect(TechTableMailer).not_to receive_message_chain(:alert_email, :deliver_now)
      expect(TechTableMailer).not_to receive(:alert_email)
      ads.update([employee])
    end

    it "should send an alert email when account update to delete attribute fails" do
      employee.office_phone = nil
      allow(ldap).to receive(:search).and_return([ldap_entry])
      allow(ldap).to receive(:delete_attribute)
      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(67) # Simulate AD LDAP error

      expect(TechTableMailer).to receive_message_chain(:alert_email, :deliver_now)
      ads.update([employee])
    end

    it "should update changed attributes with nil" do
      rem_to_reg_employee = FactoryGirl.create(:remote_employee)

      ldap_entry_2 = Net::LDAP::Entry.new(rem_to_reg_employee.dn)
      ldap_entry_2[:cn] = rem_to_reg_employee.cn
      ldap_entry_2[:objectClass] = ["top", "person", "organizationalPerson", "user"]
      ldap_entry_2[:givenName] = rem_to_reg_employee.first_name
      ldap_entry_2[:sn] = rem_to_reg_employee.last_name
      ldap_entry_2[:displayName] = rem_to_reg_employee.cn
      ldap_entry_2[:manager] = nil
      ldap_entry_2[:co] = rem_to_reg_employee.location.country
      ldap_entry_2[:accountExpires] = rem_to_reg_employee.generated_account_expires
      ldap_entry_2[:title] = rem_to_reg_employee.job_title.name
      ldap_entry_2[:description] = rem_to_reg_employee.job_title.name
      ldap_entry_2[:employeeType] = rem_to_reg_employee.worker_type.name
      ldap_entry_2[:physicalDeliveryOfficeName] = rem_to_reg_employee.location.name
      ldap_entry_2[:department] = rem_to_reg_employee.department.name
      ldap_entry_2[:employeeID] = rem_to_reg_employee.employee_id
      ldap_entry_2[:mobile] = rem_to_reg_employee.personal_mobile_phone
      ldap_entry_2[:telephoneNumber] = rem_to_reg_employee.office_phone
      ldap_entry_2[:streetAddress] = rem_to_reg_employee.generated_address
      ldap_entry_2[:l] = rem_to_reg_employee.home_city
      ldap_entry_2[:st] = rem_to_reg_employee.home_state
      ldap_entry_2[:postalCode] = rem_to_reg_employee.home_zip
      ldap_entry_2[:thumbnailPhoto] = rem_to_reg_employee.decode_img_code
      ldap_entry_2[:contract_end_date] = rem_to_reg_employee.generated_account_expires
      allow(ldap).to receive(:search).and_return([ldap_entry_2])

      rem_to_reg_employee.home_address_1 = nil
      rem_to_reg_employee.home_address_2 = nil
      rem_to_reg_employee.home_city = nil
      rem_to_reg_employee.home_state = nil
      rem_to_reg_employee.home_zip = nil

      expect(ldap).to receive(:delete_attribute).once.with(rem_to_reg_employee.dn, :streetAddress)
      expect(ldap).to receive(:delete_attribute).once.with(rem_to_reg_employee.dn, :l)
      expect(ldap).to receive(:delete_attribute).once.with(rem_to_reg_employee.dn, :st)
      expect(ldap).to receive(:delete_attribute).once.with(rem_to_reg_employee.dn, :postalCode)
      ads.update([rem_to_reg_employee])
      expect(rem_to_reg_employee.ad_updated_at).to eq(DateTime.now)
    end
  end

  context "terminate employees" do
    let(:ldap_entry) { Net::LDAP::Entry.new(employee.dn) }
    let(:employee) { FactoryGirl.create(:regular_employee,
      termination_date: Date.today - 30.days
    )}
    let!(:emp_transaction) { FactoryGirl.create(:onboarding_emp_transaction,
      employee_id: employee.id) }
    let!(:security_profile) { FactoryGirl.create(:security_profile)}
    let!(:access_level) { FactoryGirl.create(:access_level,
      ad_security_group: "cn=test")}
    let!(:access_level_2) { FactoryGirl.create(:access_level,
      ad_security_group: nil)}
    let!(:sec_prof_access_level) { FactoryGirl.create(:sec_prof_access_level,
      security_profile_id: security_profile.id,
      access_level_id: access_level.id)}
    let!(:sec_prof_access_level_2) { FactoryGirl.create(:sec_prof_access_level,
      security_profile_id: security_profile.id,
      access_level_id: access_level_2.id)}
    let!(:emp_sec_profile) { FactoryGirl.create(:emp_sec_profile,
      emp_transaction_id: emp_transaction.id,
      security_profile_id: security_profile.id)}

    before :each do
      ldap_entry[:cn] = "Jeffrey Lebowski"
      ldap_entry[:objectClass] = ["top", "person", "organizationalPerson", "user"]
      ldap_entry[:givenName] = "Jeffrey"
      ldap_entry[:sn] = "Lebowski"
      ldap_entry[:displayName] = "Jeffrey Lebowski"
      ldap_entry[:userPrincipalName] = "jlebowski@opentable.com"
      ldap_entry[:manager] = manager.dn
      ldap_entry[:co] = "US"
      ldap_entry[:accountExpires] = "9223372036854775807"
      ldap_entry[:title] = employee.job_title.name,
      ldap_entry[:description] = employee.job_title.name,
      ldap_entry[:employeeType] = employee.worker_type.name,
      ldap_entry[:physicalDeliveryOfficeName] = employee.location.name
      ldap_entry[:department] = employee.department.name
      ldap_entry[:employeeID] = employee.employee_id
      ldap_entry[:mobile] = employee.personal_mobile_phone
      ldap_entry[:telephoneNumber] = employee.office_phone
      ldap_entry[:thumbnailPhoto] = employee.decode_img_code

      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)
    end

    it "should remove the user from security groups and distribution lists" do
      expect(ldap).to receive(:modify).with({:dn=>access_level.ad_security_group, :operations=>[[:delete, :member, "#{employee.dn}"]]})
      ads.terminate([employee])
    end

    it "should not attempt to remove the user if the security group does not have an AD group" do
      expect(ldap).not_to receive(:modify).with({:dn=>access_level_2.ad_security_group, :operations=>[[:delete, :member, "#{employee.dn}"]]})
      ads.terminate([employee])
    end
  end

end
