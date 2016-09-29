class Line < ActiveRecord::Base
  self.table_name = "osm_2po_4pgr"

  scope :intersect_with_bounds, -> sw_lat, sw_lng, ne_lat, ne_lng {
    where(
			"geom_way && ST_MakeEnvelope(:sw_lng, :sw_lat, :ne_lng, :ne_lat, 4326)",
			{
				sw_lat: sw_lat,
				sw_lng: sw_lng,
				ne_lat: ne_lat,
				ne_lng: ne_lng
			}
		)
	}

  scope :intersect_with_polygon, -> polygon {
    where(
			"ST_Overlaps(geom_way, :polygon)",
			{
				polygon: polygon
			}
		)
	}

  def self.find_by_ordered_ids(*array)
    options = {}
    options = array.pop if array.last.is_a? Hash
    # pass an Array or a list of id arguments
    array = array.flatten if array.first.is_a? Array
    find(array).sort_by {|r| array.index(r.id)}
  end
end
