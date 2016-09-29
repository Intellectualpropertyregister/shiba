require 'redis_service'
require 'geo_formula'

class ReportWorker
	include Sidekiq::Worker

	def perform city_id
		puts "ReportWorker"
		@city = City.find(city_id)
		@reports = Report.search(report_time_gteq: (DateTime.now - 15.minutes), city_eq: @city.name).result
		return unless @reports
		city_name = @city.name.gsub(/\s/,'_').downcase
		redis = RedisService.new
		city_feature = redis.get_value(APP_CONFIG['city_grid_feature'] + city_name)
		row_dimension = city_feature["rowDimension"]
		col_dimension = city_feature["colDimension"]
		@reports.each do |report|
			grid_index = get_row_col_index(report.location.x, report.location.y,city_feature["rowDimension"], city_feature["distanceBetweenCells"])
			row_index = grid_index[:row]
			col_index = grid_index[:col]
			if row_index < row_dimension && col_index < col_dimension && row_index >= 0 && col_index >= 0
				grid_report = get_grid_report(city_name, row_index, col_index,redis)
				if grid_report
					report_daytime = "daytime" if report.crime_day_time == 0
					report_daytime = "dark" if report.crime_day_time == 1 || report.crime_day_time.nil?
					grid_report = generate_report_trend(grid_report,report,report_daytime)
					set_grid_report(city_name,row_index,col_index,grid_report,redis)
				end
			end
		end

		(0..row_dimension).each do |row_index|
			(0..col_dimension).each do |col_index|
				grid_report = get_grid_report(city_name, row_index, col_index,redis)
				grid_report = update_grid_safety_level(grid_report,"daytime")
				grid_report = update_grid_safety_level(grid_report,"dark")
				set_grid_report(city_name,row_index,col_index,grid_report,redis)
			end
		end
		puts "End"
	end

	private

	def update_grid_safety_level grid_report, safety_type
		return grid_report unless grid_report["reportsTrend"]
		crime_trend = grid_report["#{safety_type}CrimeTrend"]
		report_trend = grid_report["reportsTrend"]["#{safety_type}Report"]
		safety_report = grid_report["#{safety_type}SafetyReport"]
		report_time = DateTime.parse(report_trend["updatedAt"])
		total_weight = 0.0
		total_count = 0
		if (report_time.day - DateTime.now.day) < 3
			# Update daytime safety level
			crime_trend.each do |crime|
				total_weight += (crime["crimeWeight"] * crime["crimeCount"])
				total_count += crime["crimeCount"]
			end

			report_trend["reports"].each do |key,value|
				total_weight += (value["reportWeight"] * value["reportCount"])
				total_count += value["reportCount"]
			end
			grid_report = get_safety_rating(grid_report,safety_type,safety_report,total_weight,total_count)
		else
			grid_report = reset_report_field(grid_report)
			crime_trend.each do |crime|
				total_weight += (crime["crimeWeight"] * crime["crimeCount"])
				total_count += crime["crimeCount"]
			end
			grid_report = get_safety_rating(grid_report,safety_report,safety_type,total_weight,total_count)
		end
		# ap grid_report
		grid_report
	end

	def get_safety_rating grid_report, safety_type, safety_report,total_weight, total_count,
		grid_weight = total_weight/total_count
		if grid_weight >= 64
			safety_report["safetyRating"] = "LOW_SAFETY"
		elsif grid_weight >= 22 && grid_weight <= 63
			safety_report["safetyRating"] = "MODERATE"
		else
			safety_report["safetyRating"] = "MODERATELY_SAFE"
		end
		grid_report["#{safety_type}SafetyReport"] = safety_report
		grid_report
	end

	def get_grid_report city_name, row_index, col_index, redis
		grid_report_key = APP_CONFIG['city_crime_grid'] + city_name + '_' + row_index.to_s + '_' + col_index.to_s
		grid_report = redis.get_value(grid_report_key)
		grid_report
	end

	def set_grid_report city_name, row_index, col_index, grid_report, redis
		grid_report_key = APP_CONFIG['city_crime_grid'] + city_name + '_' + row_index.to_s + '_' + col_index.to_s
		redis.set_value(grid_report_key, grid_report)
	end

	def get_row_col_index lat,lng,row_dimension,distance_btw_grid
		geo = GeoFormula.new
		grid_index = Hash.new
		grid_index[:row] = geo.to_row(row_dimension,@city[:south_west].x ,lng,lat, lng, distance_btw_grid)
		grid_index[:col] = geo.to_col(lat, lng, lat, @city[:south_west].y,distance_btw_grid)
		grid_index
	end

	def generate_report_trend grid_report, report, report_daytime
		if grid_report["reportsTrend"]
			target_report = grid_report["reportsTrend"]["#{report_daytime}Report"]
			report_datetime = DateTime.parse(target_report["updatedAt"])
			if report_datetime.day - DateTime.now.day < 3
				grid_report = set_report(grid_report,report)
				target_report["updatedAt"] = DateTime.now.strftime("%Y-%m-%d %H:%M:%S")
			else
				grid_report = reset_report_field(grid_report)
				grid_report = set_report(grid_report,report)
			end
		else
			grid_report = reset_report_field(grid_report)
			grid_report = set_report(grid_report,report)
		end
		grid_report
	end

	def reset_report_field grid_report
		reports = Hash.new
		daytime_report = Hash.new
		dark_report = Hash.new
		time = DateTime.now.strftime("%Y-%m-%d %H:%M:%S")
		daytime_report["createdAt"] = time
		daytime_report["updatedAt"] = time
		dark_report["createdAt"] = time
		dark_report["updatedAt"] = time
		daytime_report["reports"] = Hash.new
		dark_report["reports"] = Hash.new
		reports["daytimeReport"] = daytime_report
		reports["darkReport"] = dark_report
		grid_report["reportsTrend"] = reports
		grid_report
	end

	def set_report grid_report, report
		reports_trend = grid_report["reportsTrend"]
		report_category = ReportCategory.find(report.report_category_id)
		if report.crime_day_time == 0
			report_type = "daytime"
		else
			report_type = "dark"
		end
		if reports_trend["#{report_type}Report"]["reports"]["#{report_category.name}"]
			reports_trend["#{report_type}Report"]["reports"]["#{report_category.name}"]["reportCount"] += 1
		else
			report_detail = Hash.new
			report_detail["reportCount"] = 1
			report_detail["reportWeight"] = report_category.weight.nil? ? 0 : report_category.weight
			reports_trend["#{report_type}Report"]["reports"]["#{report_category.name}"] = report_detail
		end
		grid_report["reportsTrend"] = reports_trend
		grid_report
	end
end
