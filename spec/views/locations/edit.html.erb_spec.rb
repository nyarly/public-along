require 'rails_helper'

RSpec.describe "locations/edit", type: :view do
  before(:each) do
    @location = assign(:location, Location.create!(
      :name => "MyString",
      :kind => "MyString",
      :country => "MyString"
    ))
  end

  it "renders the edit location form" do
    render

    assert_select "form[action=?][method=?]", location_path(@location), "post" do

      assert_select "input#location_name[name=?]", "location[name]"

      assert_select "input#location_kind[name=?]", "location[kind]"

      assert_select "input#location_country[name=?]", "location[country]"
    end
  end
end
