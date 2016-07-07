require 'rails_helper'

RSpec.describe "machine_bundles/show", type: :view do
  before(:each) do
    @machine_bundle = assign(:machine_bundle, MachineBundle.create!(
      :name => "Name",
      :description => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
  end
end
