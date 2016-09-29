json.array!(@cities) do |city|
  json.extract! city, :id, :name, :state, :country, :lowerLeftLat, :lowerLeftLng, :upperRightLng, :upperRightLng, :additionalInfo
  json.url city_url(city, format: :json)
end
