json.array!(@pois) do |poi|
  json.extract! poi, :id
  json.url poi_url(poi, format: :json)
end
