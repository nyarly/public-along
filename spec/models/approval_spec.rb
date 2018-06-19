require 'rails_helper'

RSpec.describe Approval, type: :model do
  let(:approval) { FactoryGirl.build(:approval) }

  it 'meets status presence validation' do
    expect(approval).to be_valid
  end
end
