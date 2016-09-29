# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :offense do
    description "MyString"
    score 1
    crime_type ""
  end
end
