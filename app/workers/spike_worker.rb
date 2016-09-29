require 'city_daytime'
require 'redis_service'
require 'restcall_service'
require 'geo_formula'
class SpikeWorker
	include Sidekiq::Worker

	def perform city_id
		Rails.logger.info "Start spike worker"
		@city = City.find(city_id)
		city_daytime = CityDayTime.new.get_city_time(@city.name, @city.country)
		@report = Report.search(city_eq: @city.name, crime_type_id_not_eq: 80).result
		return unless @report
		spike_report_list = Hash.new
		@report.each do |crime|
			report = get_reports(crime, @city)
			spike_report_list = check_spike(report,crime,spike_report_list)
		end

		filtered_city_name = @city.name.gsub(/ /,'_').downcase
		spike_report_list.each do |key,value|
			generate_tips_update_grid_report(value,filtered_city_name,city_daytime[:daytime])
		end
		Rails.logger.info "Done spike work"
		run_crime_matrix(city_id)
	end

	private

	# Calculate crime row_index and col_index and get the following reports
	# * Delta Report based on row_index and col_index
	# * Alert Report based on row_index and col_index
	def get_reports crime, city
		redis = RedisService.new
		lat = crime.location.y
		lng = crime.location.x
		report = Hash.new
		crime_feature_key = APP_CONFIG['city_grid_feature'] + city.name.downcase
		crime_feature = redis.get_value(crime_feature_key)
		return unless crime_feature
		row_index = GeoFormula.new.to_row(crime_feature["rowDimension"],lat ,lng, city[:south_west].y, lng, crime_feature["distanceBetweenCells"])
		col_index = GeoFormula.new.to_col(lat, lng, lat, city[:south_west].x, crime_feature["distanceBetweenCells"])
		if row_index <= crime_feature["rowDimension"] && col_index <= crime_feature["colDimension"]
			#  Get Delta Report
			city_grid_key = generate_key(APP_CONFIG['city_crime_grid'],city.name.downcase,row_index,col_index)
			delta_report_key = generate_key(APP_CONFIG['delta_report'],city.name.downcase,row_index,col_index)
			city_grid = redis.get_value(city_grid_key)
			if city_grid && crime.crime_type_id && crime.crime_day_time
				if city_grid["#{delta_report_key}"]
					delta_report = city_grid["#{delta_report_key}"]
					if crime.crime_day_time == 0
						delta_report = delta_report[:daytime_delta].nil? ? Hash.new : delta_report[:daytime_delta]
					elsif crime.crime_day_time == 1
						delta_report = delta_report[:dark_delta].nil? ? Hash.new : delta_report[:dark_delta]
					end
				else # Delta report is nil
					delta_report = Hash.new
				end
			end
			# Get Spike Report
			spike_report_key = generate_key(APP_CONFIG['spike_report'],city.name.downcase,row_index,col_index)
			spike_report = redis.get_value(spike_report_key)
			spike_report = Hash.new if spike_report.nil?

			# Store delta_report & spike_report into report
			report[:delta_report] = delta_report
			report[:spike_report] = spike_report
			report[:spike_report_key] = spike_report_key
			report[:row_index] = row_index
			report[:col_index] = col_index
		end
		report
	end

	# Generate Dynamodb Key
	def generate_key(key_base, city_name, row_index, col_index)
		return key_base + city_name + "_" + row_index.to_s + "_" + col_index.to_s
	end

	# Check Target crime type
	# Update Spike Report based on delta report
	# Return spike_alert_list for tips creation
	def check_spike report, crime, spike_report_list
		return unless report
		@crime_type = CrimeType.find(crime.crime_type_id)
		crime_type_name = @crime_type[:display_name].downcase
		if [ "theft","battery","narcotics","vehicle theft","assault","weapons violation","homicide",
	 "sex offense","sex offenses forcible" ].include? crime_type_name
			spike_report = report[:spike_report]
			delta_report = report[:delta_report]
			spike_report_time = spike_report["created_at"].nil? ? (Time.now - 60*60) : Time.parse(spike_report["created_at"])
			delta = delta_report["#{crime_type_name}"].nil? ? 0 : delta_report["#{crime_type_name}"]
			if (Time.now - spike_report_time)/ 1.hour >= 1
				spike_report = Hash.new
				spike_report["created_at"] = Time.now.to_s
				if delta < 1
					spike_report = update_spike_report(spike_report,report[:spike_report_key],crime_type_name,true)
					spike_report_list = update_spike_report_list(spike_report_list,report[:spike_report_key], spike_report, report[:row_index], report[:col_index])
				else # didn't spike
					update_spike_report(spike_report,report[:spike_report_key],crime_type_name,false)
				end
			else
				if delta < 1
					spike_report = update_spike_report(spike_report,report[:spike_report_key],crime_type_name,true)
					spike_report_list = update_spike_report_list(spike_report_list,report[:spike_report_key], spike_report, report[:row_index], report[:col_index])
				else # more than delta
					if spike_report["#{crime_type_name}"]
						if (spike_report["#{crime_type_name}"]["count"] + 1 ) >= delta
							spike_report = update_spike_report(spike_report,report[:spike_report_key],crime_type_name,true)
							spike_report_list = update_spike_report_list(spike_report_list,report[:spike_report_key], spike_report, report[:row_index], report[:col_index])
						else # crime count less than delta
							update_spike_report(spike_report,report[:spike_report_key],crime_type_name,false)
						end
					else # no crime type
						spike_report = update_spike_report(spike_report,report[:spike_report_key],crime_type_name,true)
						spike_report_list = update_spike_report_list(spike_report_list,report[:spike_report_key], spike_report, report[:row_index], report[:col_index])
					end
				end
			end
		else # Not Targeted crime type
			# DO NOTHING
		end
		spike_report_list
	end


	def update_spike_report spike_report, spike_report_key, crime_type_name, spike
		redis = RedisService.new
		if spike_report["#{crime_type_name}"]
			count = spike_report["#{crime_type_name}"]["count"].nil? ? 1 : spike_report["#{crime_type_name}"]["count"] + 1
			spike_report["#{crime_type_name}"]["count"] = count
			spike_report["#{crime_type_name}"]["spike"] = spike
		else
			spike_report["#{crime_type_name}"] = {
				"count" => 1,
				"spike" => spike
			}
		end
		redis.set_value(spike_report_key,spike_report)
		spike_report
	end

	def update_spike_report_list spike_report_list, spike_report_key, spike_report, row_index, col_index
		# ap spike_report_key
		spike_report_list["#{spike_report_key}"] = {
			:spike_report => spike_report,
			:row_index => row_index,
			:col_index => col_index
		}
		spike_report_list
	end

	def generate_tips_update_grid_report report, city_name, crime_day_time
		redis = RedisService.new
		spike_report = report[:spike_report]
		grid_report_key = generate_key(APP_CONFIG['city_crime_grid'],city_name,report[:row_index],report[:col_index])
		grid_report_value = redis.get_value(grid_report_key)
		unless grid_report_value.blank?
			# Create Tips
			spike_report.each do |key, value|
				if key != "created_at"
					latitude = grid_report_value["crimeCoordinate"]["centerLatitude"]
					longitude = grid_report_value["crimeCoordinate"]["centerLongitude"]
					create_tip(latitude, longitude, "#{value["count"]} #{key} happened around here!")
				end
			end
		end

		# Update grid safety report
		if crime_day_time == "DAYTIME"
			grid_report_value = set_safety_to_low(grid_report_value,"daytime")
		elsif crime_day_time == "DARK"
			grid_report_value = set_safety_to_low(grid_report_value,"dark")
		else
			grid_report_value = set_safety_to_low(grid_report_value,"daytime")
		end
		redis.set_value(grid_report_key,grid_report_value)
	end

	def set_safety_to_low grid, daytime
		unless grid["#{daytime}SafetyReport"].blank?
			history_rating = grid["#{daytime}SafetyReport"]["safetyRating"]
			grid["#{daytime}SafetyReport"]["safetyRating"] = "LOW_SAFETY"
			grid["#{daytime}SafetyReport"]["historySafetyRating"] = history_rating
		end
		grid
	end

	def create_tip latitude, longitude, desciption
		rest_call = RestcallService.new
		params = Hash.new
		params["#{APP_CONFIG['json_key_latitude']}"] = latitude
		params["#{APP_CONFIG['json_key_longitude']}"] = longitude
		params["#{APP_CONFIG['json_key_description']}"] = desciption
		params["#{APP_CONFIG['json_key_username']}"] = APP_CONFIG['tips_username']
		params["#{APP_CONFIG['json_key_userid']}"] = APP_CONFIG['tips_username']
		api_url = APP_CONFIG['base_url_safewalk'] + APP_CONFIG['url_safewalk_tips']
		response = rest_call.post_call(api_url,params.to_json)
	end

	def run_crime_matrix city_id
	    conn = Bunny.new(host: APP_CONFIG["rabbitmq_host"], port: APP_CONFIG["rabbitmq_port"])
	    conn.start
	    channel = conn.create_channel
	    queue  = channel.queue(APP_CONFIG["rabbitmq_queue_name"])
	    queue.publish("delta_#{city_id}_visualise")
	    conn.stop
	end
end
