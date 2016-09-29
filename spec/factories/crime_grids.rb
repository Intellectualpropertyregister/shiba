# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :crime_grid do
    city nil
    row 1
    col 1
    safety_level 1
  end
end
