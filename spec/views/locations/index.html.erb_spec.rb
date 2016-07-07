require 'rails_helper'

RSpec.describe "locations/index", type: :view do
  before(:each) do
    assign(:locations, [
      Location.create!(
        :name => "Name",
        :kind => "Kind",
        :country => "Country"
      ),
      Location.create!(
        :name => "Name",
        :kind => "Kind",
        :country => "Country"
      )
    ])
  end

  it "renders a list of locations" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Kind".to_s, :count => 2
    assert_select "tr>td", :text => "Country".to_s, :count => 2
  end
end
