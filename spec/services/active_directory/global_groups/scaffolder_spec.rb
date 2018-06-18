require 'rails_helper'

describe ActiveDirectory::GlobalGroups::Scaffolder, type: :service do
  let(:ldap)    { double(Net::LDAP) }
  let(:service) { ActiveDirectory::GlobalGroups::Scaffolder }

  before do
    allow(Net::LDAP).to receive(:new).and_return(ldap)
    allow(ldap).to receive(:host=)
    allow(ldap).to receive(:port=)
    allow(ldap).to receive(:encryption)
    allow(ldap).to receive(:auth)
    allow(ldap).to receive(:bind)
    allow(ldap).to receive(:add)
  end

  describe '.call' do
    before do
      service.call
    end

    it 'creates the mezzo managed ou' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Mezzo Managed' , objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates the groups ou' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Groups' , objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates the global groups ou' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Global Groups', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates the employee ou' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Employee', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates the temporary ou' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Temporary', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates the contractor ou' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Contractor', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates the manager ou' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Manager', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates the employee category ous' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Geographic,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Geographic', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Department', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Parent Org,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Parent Org', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates the temp category ous' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Geographic,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Geographic', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Department,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Department', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Parent Org,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Parent Org', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates the contractor category ous' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Geographic,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Geographic', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Department', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Parent Org,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Parent Org', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates the manager category ous' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Geographic,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Geographic', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Department,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Department', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Parent Org,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Parent Org', objectClass: ['top', 'organizationalUnit'] })
    end
  end
end
