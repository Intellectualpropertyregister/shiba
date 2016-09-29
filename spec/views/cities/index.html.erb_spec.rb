# require 'spec_helper'
#
# describe "cities/index" do
#   before(:each) do
#     assign(:cities, [
#       stub_model(City,
#         :name => "Name",
#         :state => "State",
#         :country => "Country",
#         :lowerLeftLat => 1.5,
#         :lowerLeftLng => 1.5,
#         :upperRightLng => 1.5,
#         :upperRightLng => 1.5,
#         :additionalInfo => "Additional Info"
#       ),
#       stub_model(City,
#         :name => "Name",
#         :state => "State",
#         :country => "Country",
#         :lowerLeftLat => 1.5,
#         :lowerLeftLng => 1.5,
#         :upperRightLng => 1.5,
#         :upperRightLng => 1.5,
#         :additionalInfo => "Additional Info"
#       )
#     ])
#   end
#
#   it "renders a list of cities" do
#     render
#     # Run the generator again with the --webrat flag if you want to use webrat matchers
#     assert_select "tr>td", :text => "Name".to_s, :count => 2
#     assert_select "tr>td", :text => "State".to_s, :count => 2
#     assert_select "tr>td", :text => "Country".to_s, :count => 2
#     assert_select "tr>td", :text => 1.5.to_s, :count => 2
#     assert_select "tr>td", :text => 1.5.to_s, :count => 2
#     assert_select "tr>td", :text => 1.5.to_s, :count => 2
#     assert_select "tr>td", :text => 1.5.to_s, :count => 2
#     assert_select "tr>td", :text => "Additional Info".to_s, :count => 2
#   end
# end
