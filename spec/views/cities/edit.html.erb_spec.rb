require 'spec_helper'

describe "cities/edit" do
  before(:each) do
    @city = assign(:city, stub_model(City,
      :name => "MyString",
      :state => "MyString",
      :country => "MyString",
      :lowerLeftLat => 1.5,
      :lowerLeftLng => 1.5,
      :upperRightLng => 1.5,
      :upperRightLng => 1.5,
      :additionalInfo => "MyString"
    ))
  end

  it "renders the edit city form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", city_path(@city), "post" do
      assert_select "input#city_name[name=?]", "city[name]"
      assert_select "input#city_state[name=?]", "city[state]"
      assert_select "input#city_country[name=?]", "city[country]"
      assert_select "input#city_lowerLeftLat[name=?]", "city[lowerLeftLat]"
      assert_select "input#city_lowerLeftLng[name=?]", "city[lowerLeftLng]"
      assert_select "input#city_upperRightLng[name=?]", "city[upperRightLng]"
      assert_select "input#city_upperRightLng[name=?]", "city[upperRightLng]"
      assert_select "input#city_additionalInfo[name=?]", "city[additionalInfo]"
    end
  end
end
