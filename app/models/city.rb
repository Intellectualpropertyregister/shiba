class City < ActiveRecord::Base
  has_and_belongs_to_many :crime_types
  
  scope :intersect_with_bounds, -> sw_lat, sw_lng, ne_lat, ne_lng {
    where(
			"area && ST_MakeEnvelope(:sw_lng, :sw_lat, :ne_lng, :ne_lat, 4326)",
			{
				sw_lat: sw_lat,
				sw_lng: sw_lng,
				ne_lat: ne_lat,
				ne_lng: ne_lng
			}
		)
	}
end
