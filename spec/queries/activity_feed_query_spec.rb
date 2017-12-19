require 'rails_helper'

describe ActivityFeedQuery, type: :query do
  context("#all") do
    let(:employee)        { FactoryGirl.create(:employee) }
    let!(:old_emp_trans)  { FactoryGirl.create(:emp_transaction,
                            employee: employee,
                            created_at: 4.days.ago) }
    let!(:new_emp_trans)  { FactoryGirl.create(:emp_transaction,
                            employee: employee,
                            created_at: 2.days.ago) }
    let!(:old_emp_delta)  { FactoryGirl.create(:emp_delta,
                            employee: employee,
                            created_at: 3.days.ago) }
    let!(:new_emp_delta)  { FactoryGirl.create(:emp_delta,
                            employee: employee,
                            created_at: 1.day.ago) }
    let!(:bad_emp_delta)  { FactoryGirl.create(:emp_delta,
                            employee: employee,
                            before: {},
                            after: {}) }

    it "should get the changes in the right order" do
      feed = ActivityFeedQuery.new(employee).all
      expect(feed).to eq([new_emp_delta, new_emp_trans, old_emp_delta, old_emp_trans])
    end
  end
end
