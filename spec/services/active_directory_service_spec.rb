require 'rails_helper'

describe ActiveDirectoryService, type: :service do
  let(:ldap)  { double(Net::LDAP) }
  let(:ads)   { ActiveDirectoryService.new }


  let(:manager)           { FactoryGirl.create(:employee) }
  let!(:manager_profile)  { FactoryGirl.create(:profile, :with_valid_ou, employee: manager) }

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

  describe '#create_disabled_accounts' do
    let(:employee)   { FactoryGirl.create(:employee,
                       first_name: 'Donny',
                       last_name: 'Kerabatsos',
                       manager: manager) }
    let!(:profile)   { FactoryGirl.create(:profile, :with_valid_ou, employee: employee) }
    let(:contractor) { FactoryGirl.create(:employee) }
    let!(:cont_prof) { FactoryGirl.create(:contractor, employee: contractor) }
    let(:ldap_err)   { OpenStruct.new(message: 'message', code: 53) }
    let(:mailer)     { double(TechTableMailer) }
    let(:pcmailer)   { double(PeopleAndCultureMailer) }

    context 'regular worker' do
      context 'with valid attributes' do
        it 'uses a newly generated sAMAccountName' do
          allow(ldap).to receive(:search).and_return('entry', 'entry', 'entry', []) # Mock search finding conflicting sAMAccountNames
          allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)
          allow(ldap).to receive(:add)

          ads.create_disabled_accounts([employee])
          expect(employee.sam_account_name).to eq('dkerabatsos1')
        end

        it 'adds account via ldap' do
          allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName
          allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)

          expect(ldap).to receive(:add).once.with(
            hash_including(
              :dn => employee.dn,
              attributes: employee.ad_attrs.merge({
                :sAMAccountName => 'dkerabatsos',
                :mail => 'dkerabatsos@opentable.com',
                :userPrincipalName => 'dkerabatsos@opentable.com'
              }).delete_if { |k,v| v.blank? || k == :dn}
            )
          )

          ads.create_disabled_accounts([employee])
        end
      end

      context 'with generic ldap error' do
        it 'sends a failure message to techtable' do
          allow(ldap).to receive(:add)
          allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName
          allow(ldap).to receive(:get_operation_result).and_return(ldap_err) # Simulate AD LDAP error

          expect(TechTableMailer).to receive(:alert).with("Active Directory Account Creation Failure", "An Active Directory account could not be created for #{employee.cn}.", [{:status=>"failure", :code=>53, :message=>"message"}]).and_return(mailer)
          expect(mailer).to receive(:deliver_now)

          ads.create_disabled_accounts([employee])
        end

        it 'adds ldap errors' do
          allow(ldap).to receive(:add)
          allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName
          allow(ldap).to receive(:get_operation_result).and_return(ldap_err) # Simulate AD LDAP error

          ads.create_disabled_accounts([employee])

          expect(ads.errors).to eq({active_directory: "Creation of disabled account for Donny Kerabatsos failed. Check the record for errors and re-submit."})
        end
      end

      context 'with sAMAccountName creation errors' do
        it 'sends failure message to techtable' do
          allow(ldap).to receive(:search).and_return("entry", "entry", "entry", "entry")
          allow(ldap).to receive(:get_operation_result).and_return(ldap_err)

          expect(TechTableMailer).to receive(:alert).with("Active Directory Account Creation Failure", "An Active Directory account could not be created for #{employee.cn}.", [{:status=>"failure", :code=>53, :message=>"message"}]).and_return(mailer)
          expect(mailer).to receive(:deliver_now)

          ads.create_disabled_accounts([employee])

          expect(employee.sam_account_name).to be(nil)
        end

        it 'adds ldap errors' do
          allow(ldap).to receive(:add)
          allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName
          allow(ldap).to receive(:get_operation_result).and_return(ldap_err) # Simulate AD LDAP error

          ads.create_disabled_accounts([employee])

          expect(ads.errors).to eq({active_directory: "Creation of disabled account for Donny Kerabatsos failed. Check the record for errors and re-submit."})
        end
      end
    end

    context 'contingent worker' do
      context 'with no worker end date' do
        it 'sends p&c a missing worker end date notice' do
          allow(ldap).to receive(:search).and_return("entry", "entry", [])
          expect(PeopleAndCultureMailer).to receive(:alert).with("Missing Worker End Date for #{contractor.cn}", "#{contractor.cn} is a contingent worker and needs a worker end date in ADP. A disabled Active Directory user has been created, but will not be enabled until a contract end date is provided.", []).and_return(pcmailer)
          expect(pcmailer).to receive(:deliver_now)
          expect(ldap).to receive(:add)
          allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)

          ads.create_disabled_accounts([contractor])

          expect(contractor.sam_account_name).not_to be(nil)
        end
      end
    end
  end

  describe '#activate' do
    let(:mailer)   { double(TechTableMailer) }
    let(:pcmailer) { double(PeopleAndCultureMailer) }

    context 'regular worker' do
      context 'without onboarding form' do
        let(:invalid_worker)  { FactoryGirl.create(:regular_employee,
                                request_status: "waiting") }

        it 'sends techtable alert' do
          expect(TechTableMailer).to receive(:alert).once.and_return(mailer)
          expect(mailer).to receive(:deliver_now).once
          ads.activate([invalid_worker])
        end

        it 'sends people & culture alert' do
          expect(PeopleAndCultureMailer).to receive(:alert).once.and_return(pcmailer)
          expect(pcmailer).to receive(:deliver_now).once
          ads.activate([invalid_worker])
        end
      end
    end

    context 'contingent worker' do
      context 'with contract end date' do
        it 'activates active directory account' do
          valid_contractor = FactoryGirl.create(:contract_worker,
                             status: "pending",
                             request_status: "completed",
                             contract_end_date: 1.year.from_now)
          emp_trans        = FactoryGirl.create(:onboarding_emp_transaction,
                             employee_id: valid_contractor.id)
          onboarding_info  = FactoryGirl.create(:onboarding_info,
                             emp_transaction_id: emp_trans.id)
          sec_prof         = FactoryGirl.create(:security_profile)
          emp_sec_prof     = FactoryGirl.create(:emp_sec_profile,
                             emp_transaction_id: emp_trans.id,
                             security_profile_id: sec_prof.id)

          allow(valid_contractor).to receive(:ou).and_return("ou=Valid OU")

          allow(ldap).to receive(:replace_attribute).once
          expect(TechTableMailer).to_not receive(:alert_email).with("ERROR: #{valid_contractor.first_name} #{valid_contractor.last_name} is a contract worker and needs a contract_end_date. Account not activated.")
          ads.activate([valid_contractor])
        end

        it 'does not need security profiles' do
          valid_contractor = FactoryGirl.create(:contract_worker,
                             status: "pending",
                             request_status: "completed",
                             contract_end_date: 1.year.from_now)
          emp_trans        = FactoryGirl.create(:onboarding_emp_transaction,
                             employee_id: valid_contractor.id)
          onboarding_info  = FactoryGirl.create(:onboarding_info,
                             emp_transaction_id: emp_trans.id)

          allow(valid_contractor).to receive(:ou).and_return("ou=Valid OU")

          allow(ldap).to receive(:replace_attribute).once
          expect(TechTableMailer).to_not receive(:alert_email).with("ERROR: #{valid_contractor.first_name} #{valid_contractor.last_name} is a contract worker and needs a contract_end_date. Account not activated.")
          ads.activate([valid_contractor])
        end
      end

      context 'without contract end date' do
        let(:invalid_contractor) { FactoryGirl.create(:contract_worker,
                             status: "pending",
                             contract_end_date: nil) }
        let(:emp_trans) { FactoryGirl.create(:onboarding_emp_transaction,
                             employee_id: invalid_contractor.id) }
        let(:sec_prof)     { FactoryGirl.create(:security_profile) }
        let(:emp_sec_prof) { FactoryGirl.create(:emp_sec_profile,
                             emp_transaction_id: emp_trans.id,
                             security_profile_id: sec_prof.id) }

        it 'sends techtable and people & culture alert emails' do
          allow(invalid_contractor).to receive(:ou).and_return("ou=Valid OU")

          expect(TechTableMailer).to receive(:alert).once.and_return(pcmailer)
          expect(mailer).to receive(:deliver_now).once
          expect(PeopleAndCultureMailer).to receive(:alert).once.and_return(mailer)
          expect(pcmailer).to receive(:deliver_now).once

          ads.activate([invalid_contractor])
        end
      end
    end
  end

  describe '#assign_sAMAccountName' do
    context 'on success' do
      let(:employee)  { FactoryGirl.create(:employee,
                        first_name: 'Walter',
                        last_name: 'Sobchak') }

      it 'finds and assigns available name' do
        allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName

        expect(ads.assign_sAMAccountName(employee)).to eq(true)
        expect(employee.sam_account_name).to eq('wsobchak')
      end

      context 'with special characters' do
        let(:employee)  { FactoryGirl.create(:employee,
                          first_name: 'Mæby',
                          last_name: 'Fünke Spløsh') }

        it 'creates account name with normalized characters' do
          allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName

          expect(ads.assign_sAMAccountName(employee)).to eq(true)
          expect(employee.sam_account_name).to eq('mfunkesplosh')
        end
      end

      context 'on failure' do
        it 'does not assign account name' do
          employee = FactoryGirl.create(:employee)

          allow(ldap).to receive(:search).and_return('entry') # Mock search finding conflicting existing sAMAccountName

          expect(ads.assign_sAMAccountName(employee)).to eq(false)
          expect(employee.sam_account_name).to eq(nil)
        end
      end
    end
  end

  describe '#update' do
    let(:ldap_entry)    { Net::LDAP::Entry.new(employee.dn) }
    let(:mailer)        { double(TechTableMailer) }
    let(:ldap_err)      { OpenStruct.new(code: '99') }
    let!(:worker_type)  { FactoryGirl.create(:worker_type) }
    let!(:job_title)    { FactoryGirl.create(:job_title) }
    let(:location)      { Location.find_or_create_by(name: 'San Francisco Headquarters') }
    let(:department)    { Department.find_or_create_by(name: 'People & Culture-HR & Total Rewards') }
    let(:employee) do
      FactoryGirl.create(:employee,
        first_name: "Jeffrey",
        last_name: "Lebowski",
        office_phone: "123-456-7890",
        sam_account_name: "jlebowski",
        manager: manager)
    end

    let!(:profile) do
      FactoryGirl.create(:profile,
        employee: employee,
        department: department,
        location: location,
        job_title: job_title,
        adp_employee_id: "12345678")
    end

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
      ldap_entry[:department] = department.name
      ldap_entry[:employeeID] = "12345678"
      ldap_entry[:mobile] = "123-456-7890"
      ldap_entry[:telephoneNumber] = "123-456-7890"
      ldap_entry[:thumbnailPhoto] = employee.decode_img_code


      allow(ldap).to receive(:search).and_return([ldap_entry])
      allow(ldap).to receive_message_chain(:get_operation_result, :message).and_return("message")
      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)
      allow(ldap).to receive(:replace_attribute)
      allow(ldap).to receive(:rename)
    end

    context 'when attributes changed' do
      let(:new_job_title) { FactoryGirl.create(:job_title) }

      before do
        ldap_entry[:title] = 'Old title'
        ldap_entry[:description] = 'Old title'
        employee.first_name = 'The Dude'
        employee.office_phone = '555-555-5555'

        ads.update([employee])
      end

      it 'updates ldap with new values' do
        expect(ldap).to have_received(:replace_attribute).once.with(employee.dn, :givenName, "The Dude")
        expect(ldap).to have_received(:replace_attribute).once.with(employee.dn, :telephoneNumber, "555-555-5555")
        expect(ldap).to have_received(:replace_attribute).once.with(employee.dn, :description, job_title.name)
        expect(ldap).to have_received(:replace_attribute).once.with(employee.dn, :title, job_title.name)
        expect(employee.ad_updated_at).to eq(DateTime.now)
      end
    end

    context 'when worker name has special character' do
      let(:dn) { "CN=Jeffrey Ordo\xC3\xB1ez,OU=Peopel and Culture,OU=Users,OU=OT,DC=ottest,DC=opentable,DC=com" }

      before do
        employee.last_name = "Ordoñez"
        allow(ldap_entry).to receive(:dn).and_return(dn.force_encoding(Encoding::ASCII_8BIT))

        ads.update([employee])
      end

      it 'encodes name correctly' do
        expect(ldap).to have_received(:rename).once.with(
          :olddn => "#{dn.force_encoding(Encoding::ASCII_8BIT)}",
          :newrdn => "cn=Jeffrey Ordoñez".force_encoding(Encoding::ASCII_8BIT),
          :delete_attributes => true,
          :new_superior => "ou=People and Culture,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"
        )
        expect(ldap).to have_received(:replace_attribute).once
          .with(
            employee.dn.force_encoding(Encoding::ASCII_8BIT),
            :displayName, "Jeffrey Ordo\xC3\xB1ez".force_encoding(Encoding::ASCII_8BIT)
            )
        expect(ldap).to have_received(:replace_attribute).once
          .with(
            employee.dn.force_encoding(Encoding::ASCII_8BIT),
            :sn, "Ordo\xC3\xB1ez".force_encoding(Encoding::ASCII_8BIT)
            )

        expect(employee.ad_updated_at).to eq(DateTime.now)
      end
    end

    context 'when country changes' do
      before do
        ldap_entry[:dn] = 'old dn'
        ldap_entry[:co] = 'co'

        allow(ldap).to receive(:search).and_return([ldap_entry])

        ads.update([employee])
      end

      it 'updates worker dn' do
        expect(ldap).to have_received(:replace_attribute).once.with(employee.dn, :co, 'US')
        expect(ldap).to have_received(:rename).once.with(
          :olddn => 'old dn',
          :newrdn => "cn=Jeffrey Lebowski",
          :delete_attributes => true,
          :new_superior => "ou=People and Culture,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"
        )
        expect(employee.ad_updated_at).to eq(DateTime.now)
      end
    end

    context 'when department changes' do
      let(:new_department) { Department.find_by(name: "Customer Support") }

      before do
        ldap_entry[:dn] = 'old dn'
        ldap_entry[:department] = 'old dept'

        allow(ldap).to receive(:search).and_return([ldap_entry])

        ads.update([employee])
      end

      it "should update dn if department changes" do
          expect(ldap).to have_received(:replace_attribute).once
            .with(employee.dn, :department, 'People & Culture-HR & Total Rewards')
          expect(ldap).to have_received(:rename).once.with(
            :olddn => 'old dn',
            :newrdn => 'cn=Jeffrey Lebowski',
            :delete_attributes => true,
            :new_superior => "ou=People and Culture,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"
          )

        expect(employee.ad_updated_at).to eq(DateTime.now)
      end
    end

    context 'when manager is unchanged' do
      let(:manager)   { FactoryGirl.create(:regular_employee) }
      let(:employee)  { FactoryGirl.create(:regular_employee, manager: manager) }

      before do
        ldap_entry[:manager] = "CN=#{manager.cn},OU=Provisional,OU=Users,OU=OT,DC=ottest,DC=opentable,DC=com"

        allow(ldap).to receive(:search).and_return([ldap_entry])
        ads.update([employee])
      end

      it 'does not detect changes from case sensitivity' do
        expect(ldap).not_to have_received(:replace_attribute).with(employee.dn, :manager, manager.dn)
      end
    end

    it "should not update unchanged attributes" do
      allow(ldap).to receive(:search).and_return([ldap_entry])

      expect(ldap).to_not receive(:replace_attribute)
      ads.update([employee])
      expect(employee.ad_updated_at).to be_nil
    end

    it "should send an alert email when account update fails" do
      employee.office_phone = "323-999-5555"
      employee.personal_mobile_phone = "fff"

      allow(ldap).to receive(:search).and_return([ldap_entry])
      allow(ldap).to receive(:replace_attribute).twice
      allow(ldap).to receive_message_chain(:get_operation_result).and_return(ldap_err) # Simulate AD LDAP error

      expect(TechTableMailer).to receive(:alert).and_return(mailer)
      expect(mailer).to receive(:deliver_now)

      ads.update([employee])
    end

    it "should send an alert email when account update to delete attribute fails" do
      employee.office_phone = nil
      allow(ldap).to receive(:search).and_return([ldap_entry])
      allow(ldap).to receive(:delete_attribute)
      allow(ldap).to receive(:get_operation_result).and_return(ldap_err) # Simulate AD LDAP error

      expect(TechTableMailer).to receive(:alert).and_return(mailer)
      expect(mailer).to receive(:deliver_now)

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
      ldap_entry_2[:streetAddress] = rem_to_reg_employee.address.complete_street
      ldap_entry_2[:l] = rem_to_reg_employee.address.city
      ldap_entry_2[:st] = rem_to_reg_employee.address.state_territory
      ldap_entry_2[:postalCode] = rem_to_reg_employee.address.postal_code
      ldap_entry_2[:thumbnailPhoto] = rem_to_reg_employee.decode_img_code
      ldap_entry_2[:contract_end_date] = rem_to_reg_employee.generated_account_expires
      allow(ldap).to receive(:search).and_return([ldap_entry_2])

      rem_to_reg_employee.address.line_1 = nil
      rem_to_reg_employee.address.line_2 = nil
      rem_to_reg_employee.address.city = nil
      rem_to_reg_employee.address.state_territory = nil
      rem_to_reg_employee.address.postal_code = nil

      expect(ldap).to receive(:delete_attribute).once.with(rem_to_reg_employee.dn, :streetAddress)
      expect(ldap).to receive(:delete_attribute).once.with(rem_to_reg_employee.dn, :l)
      expect(ldap).to receive(:delete_attribute).once.with(rem_to_reg_employee.dn, :st)
      expect(ldap).to receive(:delete_attribute).once.with(rem_to_reg_employee.dn, :postalCode)

      allow(ldap).to receive_message_chain(:get_operation_result, :message).and_return("message")
      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)

      ads.update([rem_to_reg_employee])

      expect(rem_to_reg_employee.ad_updated_at).to eq(DateTime.now)
    end
  end

  describe '#terminate' do
    let(:ldap_entry) { Net::LDAP::Entry.new(employee.dn) }
    let(:employee) { FactoryGirl.create(:regular_employee,
      termination_date: Date.today - 30.days) }
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
    let(:ldap_response) { OpenStruct.new(code: 0, message: "message") }

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

      allow(ldap).to receive_message_chain(:get_operation_result).and_return(ldap_response)
      allow(ldap).to receive(:message)
      allow(ldap).to receive(:code)
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
