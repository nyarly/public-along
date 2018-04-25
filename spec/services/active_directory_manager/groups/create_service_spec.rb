require 'rails_helper'

describe ActiveDirectoryManager::Groups::CreateService, type: :service do
  let(:ldap)    { double(Net::LDAP) }
  let(:service) { ActiveDirectoryManager::Groups::CreateService.new }

  before do
    allow(Net::LDAP).to receive(:new).and_return(ldap)
    allow(ldap).to receive(:host=)
    allow(ldap).to receive(:port=)
    allow(ldap).to receive(:encryption)
    allow(ldap).to receive(:auth)
    allow(ldap).to receive(:bind)
    allow(ldap).to receive(:add)
  end

  describe '#generate_all_geographic_groups' do
    before do
      FactoryGirl.create(:location, name: 'location1')
      FactoryGirl.create(:location, name: 'location2', status: 'Inactive')
      FactoryGirl.create(:country, name: 'country1')

      service.generate_all_geographic_groups
    end

    it 'creates location ous for temp worker type' do
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=location1,ou=Geographic,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'location1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates location ous for regular worker type' do
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=location1,ou=Geographic,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'location1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates location ous for contractor worker type' do
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=location1,ou=Geographic,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'location1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates country ous for temp worker type' do
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=country1,ou=Geographic,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates country ous for regular worker type' do
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=country1,ou=Geographic,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates country ous for contractor worker type' do
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=country1,ou=Geographic,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'does not create ous for inactive locations' do
      expect(ldap).not_to have_received(:add)
        .with(dn: 'ou=location2,ou=Geographic,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'location2', objectClass: ['top', 'organizationalUnit'] })
    end
  end

  describe '#generate_all_parent_org_groups' do
    before do
      FactoryGirl.create(:parent_org, name: 'porg1')
      FactoryGirl.create(:parent_org, name: 'porg2')
      FactoryGirl.create(:location, name: 'loc1')
      FactoryGirl.create(:country, name: 'country1')

      service.generate_all_parent_org_groups
    end

    it 'creates the parent org ous for temp worker type' do
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=porg1,ou=Parent Org,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'porg1', objectClass: ['top', 'organizationalUnit' ]})
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=porg2,ou=Parent Org,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'porg2', objectClass: ['top', 'organizationalUnit' ]})
    end

    it 'creates the parent org ous for regular worker type' do
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=porg1,ou=Parent Org,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'porg1', objectClass: ['top', 'organizationalUnit' ]})
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=porg2,ou=Parent Org,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'porg2', objectClass: ['top', 'organizationalUnit' ]})
    end

    it 'creates the parent org ous for contractor worker type' do
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=porg1,ou=Parent Org,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'porg1', objectClass: ['top', 'organizationalUnit' ]})
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=porg2,ou=Parent Org,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'porg2', objectClass: ['top', 'organizationalUnit' ]})
    end

    it 'creates location ous in each department' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=porg1,ou=Parent Org,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=porg1,ou=Parent Org,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=porg1,ou=Parent Org,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=porg2,ou=Parent Org,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=porg2,ou=Parent Org,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=porg2,ou=Parent Org,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates country ous in each department' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=porg1,ou=Parent Org,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=porg1,ou=Parent Org,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=porg1,ou=Parent Org,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=porg2,ou=Parent Org,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=porg2,ou=Parent Org,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=porg2,ou=Parent Org,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
    end
  end

  describe '#generate_all_department_groups' do
    before do
      FactoryGirl.create(:location, name: 'loc1')
      FactoryGirl.create(:country, name: 'country1')
      FactoryGirl.create(:department, name: 'dept1')
      FactoryGirl.create(:department, name: 'dept2')

      service.generate_all_department_groups
    end

    it 'creates department ous for temp worker type' do
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=dept1,ou=Department,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'dept1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=dept2,ou=Department,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'dept2', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates department ous for regular worker type' do
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=dept1,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'dept1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=dept2,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'dept2', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates department ous for contract worker type' do
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=dept1,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'dept1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once
        .with(dn: 'ou=dept2,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'dept2', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates location ous in each department' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=dept1,ou=Department,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=dept1,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=dept1,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=dept2,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=dept2,ou=Department,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=dept2,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates country ous in each department' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=dept1,ou=Department,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=dept1,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=dept1,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=dept2,ou=Department,ou=Temp,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=dept2,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=dept2,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
    end
  end

  describe '#generate_all_manager_groups' do
    before do
      FactoryGirl.create(:location, name: 'loc1')
      FactoryGirl.create(:country, name: 'country1')
      FactoryGirl.create(:parent_org, name: 'porg1')
      FactoryGirl.create(:department, name: 'dept1')

      service.generate_all_manager_groups
    end

    it 'creates the manager ou' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=Managers,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'Managers', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates country ous' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=Managers,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates location ous' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=Managers,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates parent org ous' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=porg1,ou=Managers,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'porg1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates parent org country ous' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=porg1,ou=Managers,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates parent org location ous' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=porg1,ou=Managers,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates department ous' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=dept1,ou=Managers,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'dept1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates department country ous' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=country1,ou=dept1,ou=Managers,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'country1', objectClass: ['top', 'organizationalUnit'] })
    end

    it 'creates department location ous' do
      expect(ldap).to have_received(:add).once.with(dn: 'ou=loc1,ou=dept1,ou=Managers,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'loc1', objectClass: ['top', 'organizationalUnit'] })
    end
  end
end
