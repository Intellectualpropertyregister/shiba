json.array!(@crime_type_descriptions) do |crime_type_description|
  json.extract! crime_type_description, :id
  json.url crime_type_description_url(crime_type_description, format: :json)
end
