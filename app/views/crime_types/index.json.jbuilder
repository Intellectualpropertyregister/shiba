json.array!(@crime_types) do |crime_type|
  json.extract! crime_type, :id, :offense, :offense_description, :is_index_crime, :score
  json.url crime_type_url(crime_type, format: :json)
end
