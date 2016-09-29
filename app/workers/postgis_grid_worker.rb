require 'redis_service'
require 'geo_formula'

class PostgisGridWorker
	include Sidekiq::Worker

	def perform city_id
		city = City.find(city_id)

		return result[:msg] = APP_CONFIG['worker_error_city_not_found'].gsub("CITY_NAME", city_id) unless city

		Rails.logger.info "Generate City Grid #{city.name}"

		redis = RedisService.new
		city_feature = redis.get_value(city_feature_key(city))
		daytime_cache = redis.get_value(crime_matrix_cache_key(city, :daytime))
		dark_cache = redis.get_value(crime_matrix_cache_key(city, :dark))

		Rails.logger.debug "CF: #{city_feature_key(city)}"
		Rails.logger.debug "DC: #{crime_matrix_cache_key(city, :daytime)}"
		Rails.logger.debug "NC: #{crime_matrix_cache_key(city, :dark)}"

		n_row = city_feature["rowDimension"]
		n_col = city_feature["colDimension"]

		city.grid_size = city_feature["distanceBetweenCells"]
		city.total_rows = n_row
		city.total_cols = n_col
		city.save

		Rails.logger.debug "Total Row #{n_row}"
		Rails.logger.debug "Total Col #{n_col}"

		CrimeGrid.delete_all(city: city)

		rgeo_factory = city.area.factory

		for row in 0..(n_row-1)
			for col in 0..(n_col-1)
				daytime_grid = daytime_cache[row][col]
				dark_grid = dark_cache[row][col]

				sw_lat = daytime_grid["btm_right_lat"]
				sw_lng = daytime_grid["top_left_lng"]
				ne_lat = daytime_grid["top_left_lat"]
				ne_lng = daytime_grid["btm_right_lng"]

				sw = rgeo_factory.point(sw_lng, sw_lat)
				ne = rgeo_factory.point(ne_lng, ne_lat)
				area = RGeo::Cartesian::BoundingBox.create_from_points(sw, ne).to_geometry

				CrimeGrid.create!(
					city: city,
					row: row,
					col: col,
					area: area,
					daytime_safety_level: SafetyLevelConverter.from_key(daytime_grid["safety_rating"])[:int],
					dark_safety_level: SafetyLevelConverter.from_key(dark_grid["safety_rating"])[:int]
				)
			end
		end

		Rails.logger.info "Done: Postgis crime grids for #{city.name} has just been generated"

		run_route_rating(city_id)
	end

	def city_feature_key(city)
		"#{APP_CONFIG["city_grid_feature"]}" + city.name.parameterize('_')
	end

	def crime_matrix_cache_key(city, time)
		case time
		when :daytime
			"#{APP_CONFIG["cache_daytime_crime_matrix"]}" + city.name.parameterize('_')
		when :dark
			"#{APP_CONFIG["cache_dark_crime_matrix"]}" + city.name.parameterize('_')
		end
	end

	def run_route_rating city_id
    conn = Bunny.new(host: APP_CONFIG["rabbitmq_host"], port: APP_CONFIG["rabbitmq_port"])
    conn.start
    channel = conn.create_channel
    queue  = channel.queue(APP_CONFIG["rabbitmq_queue_name"])
    queue.publish("delta_#{city_id}_routerating")
    conn.stop
	end
end
