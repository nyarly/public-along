require 'rails_helper'

RSpec.describe "machine_bundles/edit", type: :view do
  before(:each) do
    @machine_bundle = assign(:machine_bundle, MachineBundle.create!(
      :name => "MyString",
      :description => "MyText"
    ))
  end

  it "renders the edit machine_bundle form" do
    render

    assert_select "form[action=?][method=?]", machine_bundle_path(@machine_bundle), "post" do

      assert_select "input#machine_bundle_name[name=?]", "machine_bundle[name]"

      assert_select "textarea#machine_bundle_description[name=?]", "machine_bundle[description]"
    end
  end
end
