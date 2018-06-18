require 'rails_helper'

describe OffboardQuery, type: :query do
  let(:parent_org_a)    { FactoryGirl.create(:parent_org, name: 'Aaa') }
  let(:parent_org_b)    { FactoryGirl.create(:parent_org, name: 'Bbb') }

  let(:dept_c) do
    FactoryGirl.create(:department,
      name: 'Ccc',
      parent_org: parent_org_a)
  end
  let(:dept_d) do
    FactoryGirl.create(:department,
      name: 'Ddd',
      parent_org: parent_org_b)
  end
  let(:dept_e) do
    FactoryGirl.create(:department,
      name: 'Eee',
      parent_org: parent_org_b)
  end

  let!(:terminating) do
    FactoryGirl.create(:profile,
      profile_status: 'active',
      department: dept_e,
      employee_args: {
        last_name: 'Ggg',
        termination_date: Date.new(2017, 12, 11),
        status: 'active'})
  end
  let!(:terminated) do
    FactoryGirl.create(:profile,
      profile_status: 'terminated',
      department: dept_c,
      employee_args: {
        termination_date: Date.new(2017, 12, 10),
        last_name: 'Aaa',
        status: 'terminated'})
  end
  let!(:offboarded) do
    FactoryGirl.create(:profile,
      profile_status: 'terminated',
      department: dept_c,
      employee_args: {
        last_name: 'Bbb',
        status: 'terminated',
        termination_date: Date.new(2017, 12, 1),
        offboarded_at: Date.new(2017, 12, 10)})
  end
  let!(:offboarding) do
    FactoryGirl.create(:profile,
      profile_status: 'active',
      department: dept_e,
      employee_args: {
        last_name: 'Ccc',
        status: 'active',
        termination_date: Date.new(2017, 12, 11)})
  end
  let!(:contract_ending) do
    FactoryGirl.create(:contractor,
      profile_status: 'active',
      department: dept_d,
      employee_args: {
        last_name: 'Ddd',
        status: 'active',
        contract_end_date: Date.new(2017, 12, 11)})
  end
  let!(:old_offboard) do
    FactoryGirl.create(:profile,
      profile_status: 'terminated',
      start_date: Date.new(2017, 12, 06),
      department: dept_c,
      employee_args: {
        last_name: 'Eee',
        status: 'terminated',
        termination_date: Date.new(2017, 12, 06)})
  end
  let!(:old_offb_2) do
    FactoryGirl.create(:profile,
      profile_status: 'terminated',
      department: dept_d,
      employee_args: {
        last_name: 'Fff',
        status: 'terminated',
        termination_date: Date.new(2017, 11, 24)})
  end
  let!(:early_contract_term) do
    FactoryGirl.create(:profile,
      profile_status: 'terminated',
      employee_args: {
        contract_end_date: Date.new(2017, 12, 10),
        termination_date: Date.new(2017, 10, 10),
        offboarded_at: Time.new(2017, 10, 10)})
  end

  before do
    Timecop.freeze(Time.new(2017, 12, 11, 11, 0, 0, '+00:00'))
  end

  after do
    Timecop.return
  end

  describe '#report_group' do
    subject(:query) { OffboardQuery.new.report_group }

    it 'has the correct workers in order' do
      expect(query).to eq([terminated, offboarded, old_offboard, contract_ending, offboarding, terminating])
    end
  end

  describe '#added_and_updated_offboards' do
    subject(:query) { OffboardQuery.new.added_and_updated_offboards }

    it 'has the correct workers in order' do
      expect(query).to eq([contract_ending, offboarding, terminating])
    end
  end
end

