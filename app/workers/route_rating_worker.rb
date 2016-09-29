require 'redis_service'
require 'geo_formula'

class RouteRatingWorker
	include Sidekiq::Worker

	def perform city_id
		city = City.find(city_id)
    lines = Line.intersect_with_bounds(city.south_west.y, city.south_west.x, city.north_east.y, city.north_east.x)
		@rrs =  RouteRatingService.new(city)

		Rails.logger.info "Start route rating worker for #{city.name}"

		count = 0
		lines.all.each do |line|
			route_rating(line)
			count += 1
			Rails.logger.debug "Processing # #{count}" if (count % 10000 == 0)
		end

		Rails.logger.info "Route rating worker for #{city.name} has just been done"
		run_poiworker_grid(city_id)
	end

	def route_rating(line)
		safety_level_cost_rate(line)
		multilevel_street_rate(line)
		line.save
	end

	def safety_level_cost_rate(line)
		prev_point = nil
		total_distance = 0.0
		daytime_safety_level = 0.0
		dark_safety_level = 0.0
		daytime_unknown = false
		dark_unknown = false

		rated_points = @rrs.rate(line)

		rated_points.each do |current_point|
			if prev_point then
				distance = GeoFormula.new.distance(prev_point[:lat], prev_point[:lng], current_point[:lat], current_point[:lng])
				total_distance += distance
				factor = distance / 2
				daytime_safety_level += (prev_point[:daytime_safety_level][:cost] + current_point[:daytime_safety_level][:cost]) * factor
				dark_safety_level += (prev_point[:dark_safety_level][:cost] + current_point[:dark_safety_level][:cost])  * factor
			end

			daytime_unknown = true if current_point[:daytime_safety_level][:key] == "UNKNOWN"
			dark_unknown = true if current_point[:dark_safety_level][:key] == "UNKNOWN"

			prev_point = current_point
		end

		line.daytime_cost = daytime_safety_level
		line.dark_cost = dark_safety_level
		if total_distance > 0.0
			line.daytime_safety_level = SafetyLevelConverter.from_cost(daytime_safety_level / total_distance)[:int]
			line.dark_safety_level = SafetyLevelConverter.from_cost(dark_safety_level / total_distance)[:int]
		else
			line.daytime_safety_level = SafetyLevelConverter.from_key("MODERATELY_SAFE")[:int]
			line.dark_safety_level = SafetyLevelConverter.from_key("MODERATELY_SAFE")[:int]
		end

		if daytime_unknown then
			line.daytime_cost = SafetyLevelConverter.unknown[:cost] * total_distance
			line.daytime_safety_level = SafetyLevelConverter.unknown[:int]
		end

		if dark_unknown then
			line.dark_cost = SafetyLevelConverter.unknown[:cost] * total_distance
			line.dark_safety_level = SafetyLevelConverter.unknown[:int]
		end
	end

	def multilevel_street_rate(line)
		return unless line.osm_name
		if line.osm_name.start_with?("Lower ") then
			multiplier = 10
			line.daytime_cost *= multiplier
			line.dark_cost *= multiplier
		elsif line.osm_name.start_with?("Middle ") then
			multiplier = 5
			line.daytime_cost *= multiplier
			line.dark_cost *= multiplier
		end
	end

	def run_poiworker_grid city_id
	    conn = Bunny.new(host: APP_CONFIG["rabbitmq_host"], port: APP_CONFIG["rabbitmq_port"])
	    conn.start
	    channel = conn.create_channel
	    queue  = channel.queue(APP_CONFIG["rabbitmq_queue_name"])
	    queue.publish("delta_#{city_id}_poiworker")
	    conn.stop
	end

end
