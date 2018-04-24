require 'rails_helper'

describe ActiveDirectoryManager::CreateUserAccount, type: :service do
  describe '#call' do
    subject(:ad_user_service) { ActiveDirectoryManager::CreateUserAccount.new }

    let(:ldap)     { instance_double(Net::LDAP) }
    let(:manager)  { FactoryGirl.create(:manager) }
    let(:employee) do
      FactoryGirl.create(:employee,
        first_name: 'Donny',
        last_name: 'Kerabatsos',
        manager: manager)
    end

    before do
      allow(Net::LDAP).to receive(:new).and_return(ldap)
      allow(ldap).to receive(:host=)
      allow(ldap).to receive(:port=)
      allow(ldap).to receive(:encryption)
      allow(ldap).to receive(:auth)
      allow(ldap).to receive(:bind)
      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)
      allow(ldap).to receive(:add)
    end

    context 'when regular worker' do
      before do
        allow(ldap).to receive(:search).and_return([])

        FactoryGirl.create(:profile, :with_valid_ou,
          employee: employee)

        ad_user_service.call(employee)
      end

      it 'adds the account via ldap' do
        expect(ldap).to have_received(:add).once.with(
          dn: 'cn=Donny Kerabatsos,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          attributes: {
            cn: 'Donny Kerabatsos',
            objectclass: ['top', 'person', 'organizationalPerson', 'user'],
            givenName: 'Donny',
            sn: 'Kerabatsos',
            displayName: 'Donny Kerabatsos',
            userPrincipalName: 'dkerabatsos@opentable.com',
            sAMAccountName: 'dkerabatsos',
            manager: "cn=#{manager.first_name} #{manager.last_name},ou=Provisional,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
            mail: 'dkerabatsos@opentable.com',
            unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
            co: 'GB',
            accountExpires: '9223372036854775807',
            title: employee.job_title.name,
            description: employee.job_title.name,
            employeeType: 'Regular Full-Time',
            physicalDeliveryOfficeName: 'London Office',
            department: 'Customer Support',
            employeeID: employee.employee_id,
            telephoneNumber: employee.office_phone
          }
        )
      end

      it 'assigns a sam_account_name' do
        expect(employee.sam_account_name).to eq('dkerabatsos')
      end
    end

    context 'when contingent worker without contract end date' do
      let(:mailer)            { double(PeopleAndCultureMailer) }
      let(:techtable_mailer)  { double(TechTableMailer) }

      before do
        allow(ldap).to receive(:search).and_return([])
        allow(PeopleAndCultureMailer).to receive(:alert).and_return(mailer)
        allow(TechTableMailer).to receive(:alert).and_return(techtable_mailer)
        allow(mailer).to receive(:deliver_now)
        allow(techtable_mailer).to receive(:deliver_now)

        FactoryGirl.create(:contractor, :with_valid_ou, employee: employee)

        ad_user_service.call(employee)
      end

      it 'assigns a sam account name' do
        expect(employee.sam_account_name).to eq('dkerabatsos')
      end

      it 'sends P&C a missing worker end date notice' do
        expect(mailer).to have_received(:deliver_now)
      end

      it 'sends TechTable a missing worker end date notice' do
        expect(techtable_mailer).to have_received(:deliver_now)
      end
    end

    context 'when standard names taken' do
      before do
        allow(ldap).to receive(:search).and_return('entry', 'entry', 'entry', [])

        FactoryGirl.create(:profile, :with_valid_ou, employee: employee)

        ad_user_service.call(employee)
      end

      it 'assigns a newly created sam_account_name' do
        expect(employee.sam_account_name).to eq('dkerabatsos1')
      end
    end

    context 'when ldap returns a generic error' do
      let(:ldap_err)  { OpenStruct.new(message: 'message', code: 53) }

      before do
        allow(ldap).to receive(:search).and_return([])
        allow(ldap).to receive(:get_operation_result).and_return(ldap_err)

        FactoryGirl.create(:profile, :with_valid_ou, employee: employee)

        ad_user_service.call(employee)
      end

      it 'has errors' do
        expect(ad_user_service.connection).to eq('')
      end

      it 'sends a failure message to TechTable' do
      end
    end

    context 'when sAMAccountName creation fails' do
      it 'has errors' do
      end

      it 'sends a failure message to TechTable' do
      end
    end
  end
end
