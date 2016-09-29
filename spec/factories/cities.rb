# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :city do
    name "MyString"
    state "MyString"
    country "MyString"
    lowerLeftLat 1.5
    lowerLeftLng 1.5
    upperRightLng 1.5
    upperRightLng 1.5
    additionalInfo "MyString"
  end
end
