require 'rails_helper'

describe ActiveDirectoryService, type: :service do
  before :each do
    @ldap = double(Net::LDAP)

    allow(Net::LDAP).to receive(:new).and_return(@ldap)
    allow(@ldap).to receive(:host=)
    allow(@ldap).to receive(:port=)
    allow(@ldap).to receive(:encryption)
    allow(@ldap).to receive(:auth)
    allow(@ldap).to receive(:bind)

    @ads = ActiveDirectoryService.new
  end

  context "create disabled employees" do
    it "should call ldap.add with correct info for regular employee" do
      employees = FactoryGirl.create_list(:employee, 1)

      allow(@ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName
      allow(@ldap).to receive(:get_operation_result)

      expect(@ldap).to receive(:add).exactly(1).times.with(
        hash_including(
          :dn => employees[0].dn,
          attributes: employees[0].attrs.merge({
            :sAMAccountName => (employees[0].first_name[0,1] + employees[0].last_name).downcase,
            :mail => (employees[0].first_name[0,1] + employees[0].last_name + "@opentable.com").downcase
          })
        )
      )

      @ads.create_disabled(employees)
    end

    it "should not call ldap.add when no sAMAccountName is found" do
      employees = FactoryGirl.create_list(:employee, 1)

      allow(@ldap).to receive(:search).and_return("entry", "entry", "entry") # Mock search finding conflicting sAMAccountNames
      allow(@ldap).to receive(:get_operation_result)

      expect(@ldap).to_not receive(:add)

      @ads.create_disabled(employees)
    end
  end

  context "assign sAMAccountName" do
    it "should return true when available sAMAccountName is found" do
      employee = FactoryGirl.create(:employee, :first_name => "Walter", :last_name => "Sobchak")

      allow(@ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName

      expect(@ads.assign_sAMAccountName(employee)).to eq(true)
      expect(employee.sAMAccountName).to eq("wsobchak")
    end

    it "should return false when no available sAMAccountName is found" do
      employee = FactoryGirl.create(:employee)

      allow(@ldap).to receive(:search).and_return("entry") # Mock search not finding conflicting existing sAMAccountName

      expect(@ads.assign_sAMAccountName(employee)).to eq(false)
      expect(employee.sAMAccountName).to eq(nil)
    end
  end

end
