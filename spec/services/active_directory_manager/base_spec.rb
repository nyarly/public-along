require 'rails_helper'

describe ActiveDirectoryManager::Base, type: :service do
  let(:ldap) { double(Net::LDAP) }

  before do
    allow(Net::LDAP).to receive(:new).and_return(ldap)
    allow(ldap).to receive(:host=)
    allow(ldap).to receive(:port=)
    allow(ldap).to receive(:encryption)
    allow(ldap).to receive(:auth)
    allow(ldap).to receive(:bind)
  end
end
