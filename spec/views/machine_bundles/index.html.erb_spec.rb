require 'rails_helper'

RSpec.describe "machine_bundles/index", type: :view do
  before(:each) do
    assign(:machine_bundles, [
      MachineBundle.create!(
        :name => "Name",
        :description => "MyText"
      ),
      MachineBundle.create!(
        :name => "Name",
        :description => "MyText"
      )
    ])
  end

  it "renders a list of machine_bundles" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
