require 'rails_helper'
require 'cancan/matchers'

xdescribe Role::Basic, :type => :model do
  let :user do FactoryGirl.create(:user) end

  describe 'abilities' do
  end
end
