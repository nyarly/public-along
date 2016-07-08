require 'rails_helper'

RSpec.describe "locations/index", type: :view do
  before(:each) do
    assign(:locations, [
      Location.create!(
        :name => "OT This",
        :kind => "Office",
        :country => "US"
      ),
      Location.create!(
        :name => "OT That",
        :kind => "Office",
        :country => "US"
      )
    ])
  end

  it "renders a list of locations" do
    render
    assert_select "tr>td", :text => "OT This".to_s, :count => 1
    assert_select "tr>td", :text => "OT That".to_s, :count => 1
    assert_select "tr>td", :text => "Office".to_s, :count => 2
    assert_select "tr>td", :text => "US".to_s, :count => 2
  end
end
