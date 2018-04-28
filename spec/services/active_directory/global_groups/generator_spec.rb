require 'rails_helper'

describe ActiveDirectory::GlobalGroups::Generator, type: :service do
  let(:ldap)    { double(Net::LDAP) }
  let(:service) { ActiveDirectory::GlobalGroups::Generator }

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
      FactoryGirl.create(:location, code: 'LOC1')
      FactoryGirl.create(:location, code: 'LOC2', status: 'Inactive')
      FactoryGirl.create(:country, iso_alpha_3: 'CO1')
      FactoryGirl.create(:parent_org, code: 'PORG1')
      FactoryGirl.create(:parent_org, code: 'PORG2')
      FactoryGirl.create(:department, code: 'DPT1')
      FactoryGirl.create(:department, code: 'DPT2')

      service.call
    end

    it 'creates location group for temp worker type' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-LOC1,ou=Geographic,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-LOC1', objectClass: ['top', 'group'] })
    end

    it 'creates location group for regular worker type' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-LOC1,ou=Geographic,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-LOC1', objectClass: ['top', 'group'] })
    end

    it 'creates location group for contractor worker type' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-LOC1,ou=Geographic,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-LOC1', objectClass: ['top', 'group'] })
    end

    it 'creates country group for temp worker type' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-CO1,ou=Geographic,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-CO1', objectClass: ['top', 'group'] })
    end

    it 'creates country group for regular worker type' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-CO1,ou=Geographic,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-CO1', objectClass: ['top', 'group'] })
    end

    it 'creates country group for contractor worker type' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-CO1,ou=Geographic,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-CO1', objectClass: ['top', 'group'] })
    end

    it 'does not create group for inactive locations' do
      expect(ldap).not_to have_received(:add).with(dn: 'cn=TEMP-LOC2,ou=Geographic,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-LOC2', objectClass: ['top', 'group'] })
    end

    it 'creates the parent org groups for temp worker type' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-PORG1,ou=Parent Org,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-PORG1', objectClass: ['top', 'group' ]})
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-PORG2,ou=Parent Org,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-PORG2', objectClass: ['top', 'group' ]})
    end

    it 'creates the parent org groups for regular worker type' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-PORG1,ou=Parent Org,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-PORG1', objectClass: ['top', 'group' ]})
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-PORG2,ou=Parent Org,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-PORG2', objectClass: ['top', 'group' ]})
    end

    it 'creates the parent org groups for contractor worker type' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-PORG1,ou=Parent Org,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-PORG1', objectClass: ['top', 'group' ]})
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-PORG2,ou=Parent Org,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-PORG2', objectClass: ['top', 'group' ]})
    end

    it 'creates location groups for each parent org' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-PORG1-LOC1,ou=Parent Org,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-PORG1-LOC1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-PORG1-LOC1,ou=Parent Org,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-PORG1-LOC1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-PORG1-LOC1,ou=Parent Org,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-PORG1-LOC1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=MGR-PORG1-LOC1,ou=Parent Org,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'MGR-PORG1-LOC1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-PORG2-LOC1,ou=Parent Org,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-PORG2-LOC1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-PORG2-LOC1,ou=Parent Org,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-PORG2-LOC1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-PORG2-LOC1,ou=Parent Org,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-PORG2-LOC1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=MGR-PORG2-LOC1,ou=Parent Org,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'MGR-PORG2-LOC1', objectClass: ['top', 'group'] })
    end

    it 'creates country groups for each parent org' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-PORG1-CO1,ou=Parent Org,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-PORG1-CO1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-PORG1-CO1,ou=Parent Org,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-PORG1-CO1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-PORG1-CO1,ou=Parent Org,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-PORG1-CO1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-PORG2-CO1,ou=Parent Org,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-PORG2-CO1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-PORG2-CO1,ou=Parent Org,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-PORG2-CO1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-PORG2-CO1,ou=Parent Org,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-PORG2-CO1', objectClass: ['top', 'group'] })
    end

    it 'creates department groups for temp worker type' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-DPT1,ou=Department,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-DPT1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-DPT2,ou=Department,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-DPT2', objectClass: ['top', 'group'] })
    end

    it 'creates department groups for regular worker type' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-DPT1,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-DPT1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-DPT2,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-DPT2', objectClass: ['top', 'group'] })
    end

    it 'creates department groups for contract worker type' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-DPT1,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-DPT1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-DPT2,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-DPT2', objectClass: ['top', 'group'] })
    end

    it 'creates location groups for each department' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-DPT1-LOC1,ou=Department,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-DPT1-LOC1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-DPT1-LOC1,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-DPT1-LOC1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-DPT1-LOC1,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-DPT1-LOC1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-DPT2-LOC1,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-DPT2-LOC1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-DPT2-LOC1,ou=Department,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-DPT2-LOC1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-DPT2-LOC1,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-DPT2-LOC1', objectClass: ['top', 'group'] })
    end

    it 'creates country groups for each department' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-DPT1-CO1,ou=Department,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-DPT1-CO1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-DPT1-CO1,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-DPT1-CO1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-DPT1-CO1,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-DPT1-CO1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-DPT2-CO1,ou=Department,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-DPT2-CO1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-DPT2-CO1,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-DPT2-CO1', objectClass: ['top', 'group'] })
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-DPT2-CO1,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-DPT2-CO1', objectClass: ['top', 'group'] })
    end

    it 'creates the all manager group' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=MGR-ALL,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'MGR-ALL', objectClass: ['top', 'group'] })
    end

    it 'creates manager country groups' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=MGR-CO1,ou=Geographic,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'MGR-CO1', objectClass: ['top', 'group'] })
    end

    it 'creates manager location groups' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=MGR-LOC1,ou=Geographic,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'MGR-LOC1', objectClass: ['top', 'group'] })
    end

    it 'creates manager parent org groups' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=MGR-PORG1,ou=Parent Org,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'MGR-PORG1', objectClass: ['top', 'group'] })
    end

    it 'creates manager parent org country groups' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=MGR-PORG1-CO1,ou=Parent Org,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'MGR-PORG1-CO1', objectClass: ['top', 'group'] })
    end

    it 'creates manager parent org location groups' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=MGR-PORG1-LOC1,ou=Parent Org,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'MGR-PORG1-LOC1', objectClass: ['top', 'group'] })
    end

    it 'creates manager department groups' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=MGR-DPT1,ou=Department,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'MGR-DPT1', objectClass: ['top', 'group'] })
    end

    it 'creates manager department country groups' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=MGR-DPT1-CO1,ou=Department,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'MGR-DPT1-CO1', objectClass: ['top', 'group'] })
    end

    it 'creates manager department location groups' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=MGR-DPT1-LOC1,ou=Department,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'MGR-DPT1-LOC1', objectClass: ['top', 'group'] })
    end
  end

  describe '.new_group' do
    before do
      FactoryGirl.create(:location, code: 'LOC')
      FactoryGirl.create(:country, iso_alpha_3: 'COU')
      FactoryGirl.create(:parent_org, code: 'PAR')
      service.new_group('NEWDEP', 'Department')
    end

    it 'creates the temp department group' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-NEWDEP,ou=Department,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-NEWDEP', objectClass: ['top', 'group'] })
    end

    it 'creates the employee department group' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-NEWDEP,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-NEWDEP', objectClass: ['top', 'group'] })
    end

    it 'creates the contractor department group' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-NEWDEP,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-NEWDEP', objectClass: ['top', 'group'] })
    end

    it 'creates the employee department location group' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-NEWDEP-LOC,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-NEWDEP-LOC', objectClass: ['top', 'group'] })
    end

    it 'creates the employee department country group' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=EMP-NEWDEP-COU,ou=Department,ou=Employee,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'EMP-NEWDEP-COU', objectClass: ['top', 'group'] })
    end

    it 'creates the temp department location group' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-NEWDEP-LOC,ou=Department,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-NEWDEP-LOC', objectClass: ['top', 'group'] })
    end

    it 'creates the temp department country group' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=TEMP-NEWDEP-COU,ou=Department,ou=Temporary,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'TEMP-NEWDEP-COU', objectClass: ['top', 'group'] })
    end

    it 'creates the contractor department location group' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-NEWDEP-LOC,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-NEWDEP-LOC', objectClass: ['top', 'group'] })
    end

    it 'creates the contractor department country group' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=CONT-NEWDEP-COU,ou=Department,ou=Contractor,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'CONT-NEWDEP-COU', objectClass: ['top', 'group'] })
    end

    it 'creates manager department groups' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=MGR-NEWDEP,ou=Department,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'MGR-NEWDEP', objectClass: ['top', 'group'] })
    end

    it 'creates manager department country groups' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=MGR-NEWDEP-COU,ou=Department,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'MGR-NEWDEP-COU', objectClass: ['top', 'group'] })
    end

    it 'creates manager department location groups' do
      expect(ldap).to have_received(:add).once.with(dn: 'cn=MGR-NEWDEP-LOC,ou=Department,ou=Manager,ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com', attributes: { cn: 'MGR-NEWDEP-LOC', objectClass: ['top', 'group'] })
    end
  end
end
