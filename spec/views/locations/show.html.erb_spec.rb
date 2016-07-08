require 'rails_helper'

RSpec.describe "locations/show", type: :view do
  before(:each) do
    @location = assign(:location, Location.create!(
      :name => "OT This",
      :kind => "Office",
      :country => "US"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/OT This/)
    expect(rendered).to match(/Office/)
    expect(rendered).to match(/US/)
  end
end
