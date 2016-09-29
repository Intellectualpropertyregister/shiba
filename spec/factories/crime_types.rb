# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :crime_type do
    id 1
    code "0123"
    offense "CRIMINAL HOMICIDE"
    offense_description "Criminal Homicide"
    is_index_crime TRUE
    score 10
  end
end