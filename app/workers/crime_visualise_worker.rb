require 'redis_service'
class CrimeVisualiseWorker
	include Sidekiq::Worker
	def perform city_id
		Rails.logger.info "START WORKING ON VISUALIZATION"
		daytime_crime_grid = []
		dark_crime_grid = []

		if city_id
			@city = City.search(id_eq: city_id).result
			city = @city[0]
			city_name = city.name.gsub(/\s/,'_').downcase
			redis = RedisService.new
			grid_features_key = APP_CONFIG['city_grid_feature'] + city_name
			grid_features  = redis.get_value(grid_features_key)
			if grid_features
				row_index = grid_features["rowDimension"].nil? ? 0 : grid_features["rowDimension"] - 1
				col_index = grid_features["colDimension"].nil? ? 0 : grid_features["colDimension"] - 1
				for row in 0..row_index
					daytime_col_grid = []
					dark_col_grid = []
					for col in 0..col_index
						grid_key = APP_CONFIG['city_crime_grid'] + city_name + "_" + row.to_s + "_" + col.to_s
						grid = redis.get_value(grid_key)
						# ap grid_key
						if grid
							if grid["daytimeSafetyReport"]
								daytime_col_grid = safety_rating(daytime_col_grid,grid["daytimeSafetyReport"],grid["crimeCoordinate"])
							else
								daytime_col_grid = no_rating(daytime_col_grid,grid["crimeCoordinate"])
							end

							if grid["darkSafetyReport"]
								dark_col_grid = safety_rating(dark_col_grid,grid["darkSafetyReport"],grid["crimeCoordinate"])
							else
								dark_col_grid = no_rating(dark_col_grid,grid["crimeCoordinate"])
							end

						else # grid is null
						end
					end
					daytime_crime_grid << daytime_col_grid
					dark_crime_grid << dark_col_grid
				end

			end

		end

		# ap "daytime"
		redis.set_value("#{APP_CONFIG["cache_daytime_crime_matrix"]}" + city_name,daytime_crime_grid)
		# ap "dark"
		redis.set_value("#{APP_CONFIG["cache_dark_crime_matrix"]}" + city_name,dark_crime_grid)
		Rails.logger.info "DONE"

		run_postgis_grid(city_id)
	end

	private

	def no_rating grid, coordinate
		grid << {
			"safety_rating" => "NORATING",
			"crime_count" => 0,
			"color_code" => "#9E9E9E",
			# "history_color_code" => "#9E9E9E",
			"btm_right_lat" => coordinate["btmRightLatitude"].to_f,
			"btm_right_lng" => coordinate["btmRightLongitude"].to_f,
			"top_left_lat" => coordinate["topLeftLatitude"].to_f,
			"top_left_lng" => coordinate["topLeftLongitude"].to_f
		}
		grid
	end

	def safety_rating grid, report, coordinate
		color_code = get_color_code(report["safetyRating"])
		# history_color_code = report["historySafetyRating"].nil? ? color_code : get_color_code(report["historySafetyRating"])
		grid << {
			"safety_rating" => report["safetyRating"],
			"crime_count" => report["totalCrimeCount"],
			"color_code" => color_code,
			# "history_color_code" => history_color_code,
			"btm_right_lat" => coordinate["btmRightLatitude"].to_f,
			"btm_right_lng" => coordinate["btmRightLongitude"].to_f,
			"top_left_lat" => coordinate["topLeftLatitude"].to_f,
			"top_left_lng" => coordinate["topLeftLongitude"].to_f
		}
		grid
	end

	def get_color_code safety_rating
		# ap safety_rating
		if safety_rating == "MODERATELY_SAFE"
			color_code = "#009688"
		elsif safety_rating == "MODERATE"
			color_code = "#FFC107"
		elsif safety_rating == "LOW_SAFETY"
			color_code = "#F44336"
		else
			color_code = "#9E9E9E"
		end
		color_code
	end

	def run_postgis_grid city_id
	    conn = Bunny.new(host: APP_CONFIG["rabbitmq_host"], port: APP_CONFIG["rabbitmq_port"])
	    conn.start
	    channel = conn.create_channel
	    queue  = channel.queue(APP_CONFIG["rabbitmq_queue_name"])
	    queue.publish("delta_#{city_id}_postgisgrid")
	    conn.stop
	end
end
