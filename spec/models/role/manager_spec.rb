require 'rails_helper'
require 'cancan/matchers'

describe Role::Manager, :type => :model do
  let!(:ceo)             { FactoryGirl.create(:employee, first_name: 'ceo') }
  let!(:manager)         { FactoryGirl.create(:employee, manager_id: ceo.id, parent_id: ceo.id, first_name: 'manager') }
  let!(:direct_report)   { FactoryGirl.create(:employee, manager_id: manager.id, parent_id: manager.id, first_name: 'dir repot') }
  let!(:indirect_report) { FactoryGirl.create(:employee, manager_id: direct_report.id, parent_id: direct_report.id, first_name: 'indir rep') }
  let!(:employee)        { FactoryGirl.create(:employee, first_name: 'emp') }
  let!(:user)            { FactoryGirl.create(:user, :manager, employee: manager) }

  describe 'abilities' do
    subject(:ability) { Ability.new(user) }

    context 'for Employee' do
      it 'can autocomplete' do
        expect(ability).to be_able_to(:autocomplete_name, Employee)
        expect(ability).to be_able_to(:autocomplete_email, Employee)
      end

      it 'can read direct reports' do
        expect(ability).to be_able_to(:read, direct_report)
      end

      it 'can read indirect reports' do
        expect(ability).to be_able_to(:read, indirect_report)
      end

      it 'cannot read above reporting chain' do
        expect(ability).not_to be_able_to(:read, ceo)
      end

      it 'cannot read outside reporting chain' do
        expect(ability).to_not be_able_to(:read, employee)
      end

      it 'can read direct reports of self' do
        expect(ability).to be_able_to(:direct_reports, manager)
      end

      it 'can read direct reports of direct report' do
        expect(ability).to be_able_to(:direct_reports, direct_report)
      end

      it 'can read direct reports of indirect report' do
        expect(ability).to be_able_to(:direct_reports, indirect_report)
      end

      it 'cannot read direct reports above reporting chain' do
        expect(ability).to_not be_able_to(:direct_reports, ceo)
      end

      it 'cannot read direct reports outside reporting chain' do
        expect(ability).to_not be_able_to(:direct_reports, employee)
      end
    end

    context 'for EmpTransaction' do
      let!(:direct_report_transaction) { FactoryGirl.create(:emp_transaction, employee: direct_report) }
      let!(:indirect_report_transaction) { FactoryGirl.create(:emp_transaction, employee: indirect_report) }
      let!(:ceo_transaction)  { FactoryGirl.create(:emp_transaction, employee: ceo) }

      it 'can read for direct report' do
        expect(ability).to be_able_to(:read, direct_report_transaction)
      end

      it 'can read for indirect report' do
        expect(ability).to be_able_to(:read, indirect_report_transaction)
      end

      it 'cannot read above reporting chain' do
        expect(ability).not_to be_able_to(:read, ceo_transaction)
      end
    end
  end
end
