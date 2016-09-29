require 'redis_service'
class DeltaWorker
	include Sidekiq::Worker

	def perform city_id
		Rails.logger.info "DELTA WORKER"
		@city = City.find(city_id)
		return unless @city

		filtered_city_name = @city.name.gsub(/\s/, '_').downcase

		reports = get_reports(filtered_city_name)

		grid_row_dimension = get_grid_dimensions(reports[:city_feature], "row")
		grid_col_dimension = get_grid_dimensions(reports[:city_feature], "col")

		current_grid_report = reports[:current_grid_report]
		historical_grid_report = reports[:historical_grid_report]

		(0..grid_row_dimension).each do |row|
			(0..grid_col_dimension).each do |col|
				delta_report = Hash.new
				current_grid = current_grid_report[row][col]
				historical_grid = historical_grid_report[row][col]

				delta_report[:daytime_delta] = generate_delta_report(current_grid,historical_grid,"daytimeCrimeTrend")
				delta_report[:dark_delta] = generate_delta_report(current_grid,historical_grid,"darkCrimeTrend")
				delta_report[:created_at] = Time.now.to_s

				create_delta_report(delta_report, row, col, filtered_city_name)
			end
		end
		clear_old_report(filtered_city_name)
		run_spike(city_id)
		Rails.logger.info "DONE"
	end

	private

	def get_grid_dimensions(report, dimension)
		return report["#{dimension}Dimension"].to_i - 1
	end

	# Get Required reports from DynamoDB
	# City Features
	# Grid Reports
	def get_reports city_name

		redis = RedisService.new
		reports = Hash.new
		current_grid_report = Hash.new
		historical_grid_report = Hash.new

		# Get city feature
		city_feature_key = APP_CONFIG['city_grid_feature'] + city_name
		city_feature = redis.get_value(city_feature_key)
		# Get current grid_reports
		unless city_feature.blank?
			row_dimension = city_feature["rowDimension"].nil? ? 0 : get_grid_dimensions(city_feature, "row")
			col_dimension = city_feature["colDimension"].nil? ? 0 : get_grid_dimensions(city_feature, "col")
			if row_dimension > 0 && col_dimension > 0

				(0..row_dimension).each do |row_index|
					current_col_grid = Hash.new
					historical_col_grid = Hash.new

					(0..col_dimension).each do |col_index|
						# Current Grid Report
						current_grid_report_key = generate_key(APP_CONFIG['city_crime_grid'],city_name,row_index,col_index)
						current_grid_report_value = redis.get_value(current_grid_report_key)
						# Rails.logger.info "current_grid_report_key : #{current_grid_report_key}"

						current_col_grid[col_index] = current_grid_report_value if current_grid_report_value

						# Historical Grid Report
						historical_grid_report_key = current_grid_report_key + APP_CONFIG['history_report']
						# historical_grid_report_value = dynamodb.get_value(APP_CONFIG['dynamodb_ss'], historical_grid_report_key)
						historical_grid_report_value = redis.get_value(historical_grid_report_key)
						historical_col_grid[col_index] = historical_grid_report_value if historical_grid_report_value
					end

					current_grid_report[row_index] = current_col_grid
					historical_grid_report[row_index] = historical_col_grid
				end
			end
		end

		reports[:city_feature] = city_feature.nil? ? Hash.new : city_feature
		reports[:current_grid_report] = current_grid_report
		reports[:historical_grid_report] = historical_grid_report
		reports
	end

	# Generate delta report based on crime trend
	def generate_delta_report current_grid, historical_grid, daytime
		delta_report = Hash.new
		return delta_report unless current_grid && historical_grid
		current_crime_trend = filter_crime_trend(current_grid["#{daytime}"])
		historical_crime_trend = filter_crime_trend(historical_grid["#{daytime}"])
		delta_report = current_crime_trend.merge(historical_crime_trend){|key, his_val, cur_val|
							cur_val.to_f/(cur_val.to_f + his_val.to_f)}
		delta_report
	end

	# Filter targeted crime type
	def filter_crime_trend crime_trend
		filtered_report = Hash.new
		crime_trend.each do |crime_type|
			crime_type_name = crime_type["crimeType"]
			if [ "theft","battery","narcotics","vehicle theft","assault","weapons violation","homicide",
			 "sex offense","sex offenses forcible" ].include? crime_type_name
				filtered_report[crime_type_name] = crime_type["crimeCount"]
			end
		end
		filtered_report
	end

	# Create Delta Report and Attach inside grid report
	def create_delta_report delta_report, row_index, col_index, city_name
		redis = RedisService.new
		grid_report_key = generate_key(APP_CONFIG['city_crime_grid'],city_name,row_index,col_index)
		delta_report_key = "delta_report"

		grid_report = redis.get_value(grid_report_key)
		grid_report[delta_report_key] = delta_report
		redis.set_value(grid_report_key,grid_report)
		# ap "delta_report_key : #{delta_report_key}"

	end

	def generate_key(key_base, city_name, row_index, col_index)
		return key_base + city_name + "_" + row_index.to_s + "_" + col_index.to_s
	end

	def clear_old_report city_name
		redis = RedisService.new
		city_feature_key = APP_CONFIG['city_grid_feature'] + city_name
		city_feature = redis.get_value(city_feature_key)

		row_dimension = city_feature["rowDimension"].nil? ? 0 : get_grid_dimensions(city_feature, "row")
		col_dimension = city_feature["colDimension"].nil? ? 0 : get_grid_dimensions(city_feature, "col")

		(0..row_dimension).each do |row_index|
			(0..col_dimension).each do |col_index|
				historical_grid_report_key = generate_key(APP_CONFIG['city_crime_grid'],city_name,row_index,col_index) + APP_CONFIG['history_report']
				redis.del_value(historical_grid_report_key)
			end
		end

	end

	# Check for spike
	def run_spike city_id
	    conn = Bunny.new(host: APP_CONFIG["rabbitmq_host"], port: APP_CONFIG["rabbitmq_port"])
	    conn.start
	    channel = conn.create_channel
	    queue  = channel.queue(APP_CONFIG["rabbitmq_queue_name"])
	    queue.publish("delta_#{city_id}_spike")
	    conn.stop
	end
end
