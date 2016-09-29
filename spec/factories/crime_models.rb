# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :crime_model do
    crime_type 1
    crime_wday ""
    crime_time 1
    community_area 1
    district 1
  end
end
