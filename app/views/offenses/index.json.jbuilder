json.array!(@offenses) do |offense|
  json.extract! offense, :id, :description, :score, :crime_type
  json.url offense_url(offense, format: :json)
end
