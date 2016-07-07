require 'rails_helper'

RSpec.describe "machine_bundles/new", type: :view do
  before(:each) do
    assign(:machine_bundle, MachineBundle.new(
      :name => "MyString",
      :description => "MyText"
    ))
  end

  it "renders new machine_bundle form" do
    render

    assert_select "form[action=?][method=?]", machine_bundles_path, "post" do

      assert_select "input#machine_bundle_name[name=?]", "machine_bundle[name]"

      assert_select "textarea#machine_bundle_description[name=?]", "machine_bundle[description]"
    end
  end
end
