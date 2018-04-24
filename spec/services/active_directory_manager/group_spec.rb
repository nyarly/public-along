require 'rails_helper'

describe ActiveDirectoryManager::Group, type: :service do
  let(:ldap) { double(Net::LDAP) }
  let(:group_manager) { ActiveDirectoryManager::Group.new }

  before do
    allow(Net::LDAP).to receieve(:new).and_return(ldap)
    allow(ldap).to receieve(:host=)
    allow(ldap).to receieve(:port=)
    allow(ldap).to receieve(:encryption)
    allow(ldap).to receieve(:auth)
    allow(ldap).to receieve(:bind)
  end

  describe '#new_security_group' do
    context 'when based on location' do
      let(:location) { FactoryGirl.create(:location) }

      it 'creates a correctly named security group' do
        expect(group_manager.new_security_group())
      end
    end

    context 'when based on parent department' do
    end

    context 'when based on department' do
    end

    context 'when based on manager' do
    end
  end
end
