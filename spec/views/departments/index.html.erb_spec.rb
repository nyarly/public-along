require 'rails_helper'

RSpec.describe "departments/index", type: :view do
  before(:each) do
    assign(:departments, [
      Department.create!(
        :name => "Name1",
        :code => "Code1"
      ),
      Department.create!(
        :name => "Name2",
        :code => "Code2"
      )
    ])
  end

  it "renders a list of departments" do
    render
    assert_select "tr>td", :text => "Name1".to_s, :count => 1
    assert_select "tr>td", :text => "Name2".to_s, :count => 1
    assert_select "tr>td", :text => "Code1".to_s, :count => 1
    assert_select "tr>td", :text => "Code2".to_s, :count => 1
  end
end
