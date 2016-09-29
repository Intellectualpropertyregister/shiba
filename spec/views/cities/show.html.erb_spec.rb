require 'spec_helper'

describe "cities/show" do
  before(:each) do
    @city = assign(:city, stub_model(City,
      :name => "Name",
      :state => "State",
      :country => "Country",
      :lowerLeftLat => 1.5,
      :lowerLeftLng => 1.5,
      :upperRightLng => 1.5,
      :upperRightLng => 1.5,
      :additionalInfo => "Additional Info"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/State/)
    rendered.should match(/Country/)
    rendered.should match(/1.5/)
    rendered.should match(/1.5/)
    rendered.should match(/1.5/)
    rendered.should match(/1.5/)
    rendered.should match(/Additional Info/)
  end
end
