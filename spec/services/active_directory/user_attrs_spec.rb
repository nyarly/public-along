require 'rails_helper'

describe ActiveDirectoryManager::UserAttrs, type: :service do
  describe '#all' do

    let(:manager) do
      FactoryGirl.create(:employee,
        status: 'active',
        email: nil,
        first_name: 'Mfname',
        last_name: 'Mlname')
    end

    before do
      FactoryGirl.create(:profile, :with_valid_ou,
        employee: manager,
        profile_status: 'active')
    end

    context 'with regular worker with assigned email' do
      subject(:attrs) { user_attrs.all }

      let(:user_attrs) { ActiveDirectoryManager::UserAttrs.new(employee) }
      let(:employee) do
        FactoryGirl.create(:employee,
          status: 'active',
          first_name: 'Fname',
          last_name: 'Lname',
          sam_account_name: 'flname',
          email: 'flname@opentable.com',
          manager: manager)
      end

      before do
        FactoryGirl.create(:profile, :with_valid_ou,
          employee: employee,
          profile_status: 'active')
      end

      it 'creates the attr hash' do
        expect(attrs).to eq(
          cn: 'Fname Lname',
          dn: 'cn=Fname Lname,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          objectclass: ['top', 'person', 'organizationalPerson', 'user'],
          givenName: 'Fname',
          sn: 'Lname',
          sAMAccountName: 'flname',
          displayName: 'Fname Lname',
          userPrincipalName: 'flname@opentable.com',
          manager: 'cn=Mfname Mlname,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          mail: 'flname@opentable.com',
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          co: employee.location.country,
          accountExpires: '9223372036854775807',
          title: employee.job_title.name,
          description: employee.job_title.name,
          employeeType: employee.worker_type.name,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          telephoneNumber: employee.office_phone,
          streetAddress: nil,
          l: nil,
          st: nil,
          postalCode: nil
        )
      end
    end

    context 'with worker without email' do
      subject(:attrs) { user_attrs.all }

      let(:user_attrs) { ActiveDirectoryManager::UserAttrs.new(employee) }
      let(:employee) do
        FactoryGirl.create(:employee,
          status: 'active',
          first_name: 'Fname',
          last_name: 'Lname',
          sam_account_name: 'flname',
          manager: manager)
      end

      before do
        FactoryGirl.create(:profile, :with_valid_ou,
          employee: employee,
          profile_status: 'active')
      end

      it 'assigns an email address to the employee' do
        expect(attrs[:mail]).to eq('flname@opentable.com')
        expect(employee.email).to eq('flname@opentable.com')
      end

      it 'assigns a userPrincipalName' do
        expect(attrs[:userPrincipalName]).to eq('flname@opentable.com')
      end

      it 'creates the attr hash' do
        expect(attrs).to eq(
          cn: 'Fname Lname',
          dn: 'cn=Fname Lname,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          objectclass: ['top', 'person', 'organizationalPerson', 'user'],
          givenName: 'Fname',
          sn: 'Lname',
          sAMAccountName: 'flname',
          displayName: 'Fname Lname',
          userPrincipalName: 'flname@opentable.com',
          manager: 'cn=Mfname Mlname,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          mail: 'flname@opentable.com',
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          co: employee.location.country,
          accountExpires: '9223372036854775807',
          title: employee.job_title.name,
          description: employee.job_title.name,
          employeeType: employee.worker_type.name,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          telephoneNumber: employee.office_phone,
          streetAddress: nil,
          l: nil,
          st: nil,
          postalCode: nil
        )
      end
    end

    context 'with a terminated worker' do
      subject(:attrs) { user_attrs.all }

      let(:user_attrs) { ActiveDirectoryManager::UserAttrs.new(employee) }
      let(:expiry)     { employee.termination_date + 1.day }
      let(:expiry_utc) { ActiveSupport::TimeZone.new('Europe/London').local_to_utc(expiry) }
      let(:ldap_time)  { DateTimeHelper::FileTime.wtime(expiry_utc) }
      let(:employee) do
        FactoryGirl.create(:employee,
          status: 'terminated',
          first_name: 'Fname',
          last_name: 'Lname',
          sam_account_name: 'flname',
          manager: manager,
          termination_date: 1.day.from_now)
      end

      before do
        FactoryGirl.create(:contractor, :with_valid_ou,
          employee: employee,
          profile_status: 'terminated')
      end

      it 'set the correct expiry date' do
        expect(attrs[:accountExpires]).to eq(ldap_time)
      end

      it 'creates the attr hash' do
        expect(attrs).to eq(
          cn: 'Fname Lname',
          dn: 'cn=Fname Lname,ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          objectclass: ['top', 'person', 'organizationalPerson', 'user'],
          givenName: 'Fname',
          sn: 'Lname',
          sAMAccountName: 'flname',
          displayName: 'Fname Lname',
          userPrincipalName: 'flname@opentable.com',
          manager: 'cn=Mfname Mlname,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          mail: 'flname@opentable.com',
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          co: employee.location.country,
          accountExpires: ldap_time,
          title: employee.job_title.name,
          description: employee.job_title.name,
          employeeType: employee.worker_type.name,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          telephoneNumber: employee.office_phone,
          streetAddress: nil,
          l: nil,
          st: nil,
          postalCode: nil
        )
      end
    end

    context 'with contingent worker' do
      subject(:attrs) { user_attrs.all }

      let(:user_attrs) { ActiveDirectoryManager::UserAttrs.new(employee) }
      let(:expiry)     { employee.contract_end_date + 1.day }
      let(:expiry_utc) { ActiveSupport::TimeZone.new('Europe/London').local_to_utc(expiry) }
      let(:ldap_time)  { DateTimeHelper::FileTime.wtime(expiry_utc) }
      let(:employee) do
        FactoryGirl.create(:employee,
          status: 'active',
          first_name: 'Fname',
          last_name: 'Lname',
          sam_account_name: 'flname',
          manager: manager,
          contract_end_date: 1.month.from_now)
      end

      before do
        FactoryGirl.create(:contractor, :with_valid_ou,
          employee: employee,
          profile_status: 'active')
      end

      it 'sets expiry date to contract end date' do
        expect(attrs[:accountExpires]).to eq(ldap_time)
      end

      it 'creates the attr hash' do
        expect(attrs).to eq(
          cn: 'Fname Lname',
          dn: 'cn=Fname Lname,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          objectclass: ['top', 'person', 'organizationalPerson', 'user'],
          givenName: 'Fname',
          sn: 'Lname',
          sAMAccountName: 'flname',
          displayName: 'Fname Lname',
          userPrincipalName: 'flname@opentable.com',
          manager: 'cn=Mfname Mlname,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          mail: 'flname@opentable.com',
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          co: employee.location.country,
          accountExpires: ldap_time,
          title: employee.job_title.name,
          description: employee.job_title.name,
          employeeType: employee.worker_type.name,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          telephoneNumber: employee.office_phone,
          streetAddress: nil,
          l: nil,
          st: nil,
          postalCode: nil
        )
      end
    end

    context 'with a terminating contingent worker' do
      subject(:attrs) { user_attrs.all }

      let(:user_attrs) { ActiveDirectoryManager::UserAttrs.new(employee) }
      let(:expiry)     { employee.termination_date + 1.day }
      let(:expiry_utc) { ActiveSupport::TimeZone.new('Europe/London').local_to_utc(expiry) }
      let(:ldap_time)  { DateTimeHelper::FileTime.wtime(expiry_utc) }
      let(:employee) do
        FactoryGirl.create(:employee,
          status: 'active',
          first_name: 'Fname',
          last_name: 'Lname',
          sam_account_name: 'flname',
          manager: manager,
          contract_end_date: 1.month.from_now,
          termination_date: 1.day.from_now)
      end

      before do
        FactoryGirl.create(:contractor, :with_valid_ou,
          employee: employee,
          profile_status: 'active')
      end

      it 'sets the expiry date to the contract end date' do
        expect(attrs[:accountExpires]).to eq(ldap_time)
      end

      it 'creates the attr hash' do
        expect(attrs).to eq(
          cn: 'Fname Lname',
          dn: 'cn=Fname Lname,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          objectclass: ['top', 'person', 'organizationalPerson', 'user'],
          givenName: 'Fname',
          sn: 'Lname',
          sAMAccountName: 'flname',
          displayName: 'Fname Lname',
          userPrincipalName: 'flname@opentable.com',
          manager: 'cn=Mfname Mlname,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          mail: 'flname@opentable.com',
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          co: employee.location.country,
          accountExpires: ldap_time,
          title: employee.job_title.name,
          description: employee.job_title.name,
          employeeType: employee.worker_type.name,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          telephoneNumber: employee.office_phone,
          streetAddress: nil,
          l: nil,
          st: nil,
          postalCode: nil
        )
      end
    end

    context 'with a remote worker address' do
      subject(:attrs) { user_attrs.all }

      let(:user_attrs) { ActiveDirectoryManager::UserAttrs.new(employee) }
      let(:employee) do
        FactoryGirl.create(:employee,
          status: 'active',
          first_name: 'Fname',
          last_name: 'Lname',
          sam_account_name: 'flname',
          manager: manager)
      end

      before do
        FactoryGirl.create(:contractor, :with_valid_ou, :remote,
          employee: employee,
          profile_status: 'active')
        FactoryGirl.create(:address,
          addressable_id: employee.id,
          addressable_type: 'Employee',
          line_1: '123 Fake St',
          line_2: nil,
          city: 'Beverly Hills',
          state_territory: 'CA',
          postal_code: '90210',
          country: Country.find_by(iso_alpha_2_code: 'US'))
      end

      it 'creates the attr hash' do
        expect(attrs).to eq(
          cn: 'Fname Lname',
          dn: 'cn=Fname Lname,ou=Customer Support,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          objectclass: ['top', 'person', 'organizationalPerson', 'user'],
          givenName: 'Fname',
          sn: 'Lname',
          sAMAccountName: 'flname',
          displayName: 'Fname Lname',
          userPrincipalName: 'flname@opentable.com',
          manager: 'cn=Mfname Mlname,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          mail: 'flname@opentable.com',
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          co: employee.location.country,
          accountExpires: '9223372036854775807',
          title: employee.job_title.name,
          description: employee.job_title.name,
          employeeType: employee.worker_type.name,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          telephoneNumber: employee.office_phone,
          streetAddress: '123 Fake St',
          l: 'Beverly Hills',
          st: 'CA',
          postalCode: '90210'
        )
      end
    end

    context 'with a remote worker who has two address lines' do
      subject(:attrs) { user_attrs.all }

      let(:user_attrs) { ActiveDirectoryManager::UserAttrs.new(employee) }
      let(:employee) do
        FactoryGirl.create(:employee,
          status: 'active',
          first_name: 'Fname',
          last_name: 'Lname',
          sam_account_name: 'flname',
          manager: manager)
      end

      before do
        FactoryGirl.create(:contractor, :with_valid_ou, :remote,
          employee: employee,
          profile_status: 'active')
        FactoryGirl.create(:address,
          addressable_id: employee.id,
          addressable_type: 'Employee',
          line_1: '123 Fake St',
          line_2: 'Apt 1',
          city: 'Beverly Hills',
          state_territory: 'CA',
          postal_code: '90210',
          country: Country.find_by(iso_alpha_2_code: 'US'))
      end

      it 'creates the attr hash' do
        expect(attrs).to eq(
          cn: 'Fname Lname',
          dn: 'cn=Fname Lname,ou=Customer Support,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          objectclass: ['top', 'person', 'organizationalPerson', 'user'],
          givenName: 'Fname',
          sn: 'Lname',
          sAMAccountName: 'flname',
          displayName: 'Fname Lname',
          userPrincipalName: 'flname@opentable.com',
          manager: 'cn=Mfname Mlname,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          mail: 'flname@opentable.com',
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          co: employee.location.country,
          accountExpires: '9223372036854775807',
          title: employee.job_title.name,
          description: employee.job_title.name,
          employeeType: employee.worker_type.name,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          telephoneNumber: employee.office_phone,
          streetAddress: '123 Fake St, Apt 1',
          l: 'Beverly Hills',
          st: 'CA',
          postalCode: '90210'
        )
      end
    end

    context 'when location and department ou match is not found' do
      subject(:attrs) { user_attrs.all }

      let(:user_attrs) { ActiveDirectoryManager::UserAttrs.new(employee) }
      let(:employee) do
        FactoryGirl.create(:employee,
          status: 'active',
          first_name: 'Fname',
          last_name: 'Lname',
          sam_account_name: 'flname',
          email: 'flname@opentable.com',
          manager: manager)
      end

      before do
        FactoryGirl.create(:profile,
          employee: employee,
          profile_status: 'active')
      end

      it 'assigns the user to the provisional ou' do
        expect(attrs[:dn]).to eq('cn=Fname Lname,ou=Provisional,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com')
      end

      it 'creates the attr hash' do
        expect(attrs).to eq(
          cn: 'Fname Lname',
          dn: 'cn=Fname Lname,ou=Provisional,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          objectclass: ['top', 'person', 'organizationalPerson', 'user'],
          givenName: 'Fname',
          sn: 'Lname',
          sAMAccountName: 'flname',
          displayName: 'Fname Lname',
          userPrincipalName: 'flname@opentable.com',
          manager: 'cn=Mfname Mlname,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          mail: 'flname@opentable.com',
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          co: employee.location.country,
          accountExpires: '9223372036854775807',
          title: employee.job_title.name,
          description: employee.job_title.name,
          employeeType: employee.worker_type.name,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          telephoneNumber: employee.office_phone,
          streetAddress: nil,
          l: nil,
          st: nil,
          postalCode: nil
        )
      end
    end
  end
end
