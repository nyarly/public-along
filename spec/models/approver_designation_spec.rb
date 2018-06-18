require 'rails_helper'

RSpec.describe ApproverDesignation, type: :model do
  let(:approver_designation) { FactoryGirl.create(:approver_designation) }

  it 'is valid' do
    expect(approver_designation).to be_valid
  end

  it 'meets kind presence validation' do
    expect(approver_designation).not_to allow_value(nil).for(:kind)
  end

  it 'meets kind inclusion in KINDS validation' do
    expect(approver_designation).not_to allow_value('other').for(:kind)
  end

  it 'meets active inclusion validation' do
    expect(approver_designation).not_to allow_value(nil).for(:active)
  end
end
