require 'redis_service'
require 'geo_formula'
class CityCrimeMatrix

	include Sidekiq::Worker

	def perform city_id, old_report
		result = Hash.new

		@@zones = Zone.where(city_id: city_id)

		@city = City.find(city_id)
		return result[:msg] = APP_CONFIG['worker_error_city_not_found'].gsub("CITY_NAME",city_id) unless @city
		city_name = @city.name
		@whole_year_crime_data = CrimeData.search(occurred_at_gteq: (Date.today - 365.days), occurred_at_lteq: Date.today, city_id_eq: @city.id, crime_weight_gt: 0).result
		@poi_list = Poi.where(city_id: city_id)
		return result[:msg] = APP_CONFIG['worker_error_no_crime_data_found'].gsub("CITY_NAME",city_name) unless @whole_year_crime_data.length > 0
		if old_report
			end_date = @whole_year_crime_data.select(:occurred_at).order(:occurred_at).last[:occurred_at] - 30.days
		else
			end_date = @whole_year_crime_data.select(:occurred_at).order(:occurred_at).last[:occurred_at]
		end
		start_date = end_date - 30.days
		@crime_data = @whole_year_crime_data.search(occurred_at_gteq: start_date , occurred_at_lteq: end_date).result
		@user_streets_rating = UserStreetSafetyRatingLog.search(user_rating_time_gteq: start_date, user_rating_time_lteq: end_date, city_id_eq: @city.id).result
		return result[:msg] = APP_CONFIG['worker_error_no_crime_data_found'].gsub("CITY_NAME"),city_name unless @crime_data
		city_feature = generate_city_feature(@city, @crime_data, @user_streets_rating,start_date,end_date)
		city_matrix = generate_grid(@city, city_feature)
		city_matrix = generate_crime_report(city_matrix,@crime_data,@city,city_feature)
		city_matrix = generate_user_rating_report(city_matrix,@user_streets_rating,@city,city_feature)
		city_matrix = generate_crime_trend(city_matrix,@city,city_feature)
		city_matrix = generate_safety_report(city_matrix,@city,city_feature)
		city_matrix = generate_poi_list(city_matrix,@poi_list,@city,city_feature) if !old_report
		city_matrix = generate_grid_avg_crime(city_matrix,@whole_year_crime_data,@city,city_feature) if !old_report
		city_matrix = analyze_grid_annual_rating(city_matrix) if !old_report
		store_as_cache(@city,city_matrix,city_feature, old_report)
		Rails.logger.info "Done generating city matrix for #{@city.name} and stored inside redis"
		if old_report
			send_msg(@city.id,"delta")
		else
			send_msg(@city.id,"historycitymatrix")
		end
	end

	private

	# GENERATE GRID COORDINATES FOR CITY MATRIX & EMPTY REPORTS
	def generate_grid city, city_feature
		Rails.logger.info "Generating #{city[:name]} city_matrix"
		city_matrix = Array.new
		geo = GeoFormula.new

		total_row = city_feature["rowDimension"]
		total_col = city_feature["colDimension"]
		distance_btw_grid = city_feature["distanceBetweenCells"]

		initial_lat = city[:north_east].y
		intial_lng = city[:south_west].x

		(0..total_row).each do |row|
			col_reports = Array.new
			# Calculate the coordinate for (n)th row 1st column
			if row != 0
				coordinate = geo.project_point(initial_lat, intial_lng, 180.0, distance_btw_grid)
				col_reports << set_coordinate(coordinate[:lat], coordinate[:lng])
				initial_lat = coordinate[:lat]
				intial_lng = coordinate[:lng]
			else
				col_reports << set_coordinate(initial_lat, intial_lng)
			end

			(1..total_col).each do |col|
				coordinate = geo.project_point(initial_lat, intial_lng,90.00194,distance_btw_grid * col)
				col_reports << set_coordinate(coordinate[:lat],coordinate[:lng])
			end
			city_matrix << col_reports
		end
		Rails.logger.info "Done generating city_matrix"
		city_matrix
	end

	#  GENERATE CRIME MATRIX FOR CITY
	def generate_crime_report city_matrix, crime_list,city, city_feature
		Rails.logger.info "Generate #{city.name} crime report"
		return city_matrix unless city_matrix && crime_list
		row_dimension = city_feature["rowDimension"]
		distance_btw_grid = city_feature["distanceBetweenCells"]
		crime_list.each do |crime|
			grid_index = get_row_col_index(crime.location.y,crime.location.x,city[:north_east].y,city[:south_west].x,row_dimension,distance_btw_grid)
			row_index = grid_index[:row]
			col_index = grid_index[:col]
			if row_index < city_matrix.length && col_index < city_matrix[0].length && row_index >= 0 && col_index >= 0
				city_matrix[row_index][col_index]["daytimeReport"] << set_crime_report(crime) if crime.crime_day_time == 0
				city_matrix[row_index][col_index]["darkReport"] << set_crime_report(crime) if crime.crime_day_time == 1
			end
		end
		city_matrix
	end
	# CHANGE TO WALKY REPORTS
	def generate_user_rating_report city_matrix, rating_list,city, city_feature
		Rails.logger.info "Generate #{city.name} rating report"
		return city_matrix unless city_matrix && rating_list
		row_dimension = city_feature["rowDimension"]
		distance_btw_grid = city_feature["distanceBetweenCells"]
		rating_list.each do |rating|
			grid_index = get_row_col_index(rating.latitude,rating.longitude,city[:north_east].y,city[:south_west].x,row_dimension,distance_btw_grid)
			row_index = grid_index[:row]
			col_index = grid_index[:col]
			if row_index < city_matrix.length && col_index < city_matrix[0].length && row_index >= 0 && col_index >= 0
				city_matrix[row_index][col_index]["userStreetSafetyRatingVO"] <<  set_user_rating_report(rating)
			end
		end
		city_matrix

	end

	def get_row_col_index lat1,lng1,lat2,lng2,row_dimension,distance_btw_grid
		geo = GeoFormula.new
		grid_index = Hash.new
		grid_index[:row] = geo.to_row(row_dimension,lat2 ,lng1,lat1, lng1, distance_btw_grid)
		grid_index[:col] = geo.to_col(lat1, lng1, lat1, lng2,distance_btw_grid)
		grid_index
	end

	# GENERATE CITY FEATURES
	def generate_city_feature city, crime_list, user_rating_list,start_date, end_date
		geo = GeoFormula.new
		features = Array.new
		report_start_date = nil
		report_end_date = nil
		rating_start_date = nil
		rating_end_date = nil

		city_upper_right_lat = city[:north_east].y
		city_upper_right_lng = city[:north_east].x
		city_lower_left_lat  = city[:south_west].y
		city_lower_left_lng  = city[:south_west].x

		if crime_list && crime_list.length > 0
			report_start_date = crime_list.select(:occurred_at).order(:occurred_at).first[:occurred_at]
			report_end_date = crime_list.select(:occurred_at).order(:occurred_at).last[:occurred_at]
		end

		if user_rating_list && user_rating_list.length > 0
			rating_start_date = user_rating_list.select(:user_rating_time).order(:user_rating_time).first[:user_rating_time]
			rating_end_date = user_rating_list.select(:user_rating_time).order(:user_rating_time).last[:user_rating_time]
		end

		vertical_dimension = geo.distance(city_upper_right_lat, city_lower_left_lng, city_lower_left_lat, city_lower_left_lng)
		horizontal_dimension = geo.distance(city_upper_right_lat,city_upper_right_lng,city_upper_right_lat, city_lower_left_lng)

		total_row = (vertical_dimension/0.25).ceil
		total_col = (horizontal_dimension/0.25).ceil

		features = {
			"distanceBetweenCells" => 0.25,
			"crimeReportStartDate" => report_start_date.nil? ? start_date : report_start_date,
			"crimeReportEndDate" => report_end_date.nil? ? end_date : report_end_date,
			"userRatingStartDate" => rating_start_date.nil? ? end_date : rating_start_date,
			"userRatingEndDate" => rating_end_date.nil? ? end_date : rating_end_date,
			"maxCrimeCount" => 0,
			"averageCrimePerCell" => 0,
			"rowDimension" => total_row,
			"colDimension" => total_col
		}
		features
	end

	def generate_crime_trend city_matrix, city, crime_feature
		Rails.logger.info "Generate #{city.name} crime trend"
		return city_matrix unless city_matrix
		city_matrix.each do |row|
			row.each do|col|
				daytime_hash = Hash.new
				dark_hash = Hash.new
				daytime_hash = add_crime_type_to_hash(daytime_hash,col["daytimeReport"])
				dark_hash = add_crime_type_to_hash(dark_hash,col["darkReport"])
				col["daytimeCrimeTrend"] = convert_report_to_crime_trend(daytime_hash,city)
				col["darkCrimeTrend"] = convert_report_to_crime_trend(dark_hash,city)
			end
		end
		Rails.logger.info "Done crime trend"
		city_matrix
	end

	def add_crime_type_to_hash hash, crime_list
		return hash unless crime_list.length > 0
		crime_list.each do |crime|
			hash[crime["crimeTypeId"]] = hash[crime["crimeTypeId"]].nil? ? 1 : hash[crime["crimeTypeId"]] + 1
		end
		return hash
	end

	def convert_report_to_crime_trend hash,city
		crime_trend = Array.new
		hash.each do |key,value|
			crime_type = CrimeType.find(key)
			city_crime_type = CitiesCrimeTypeWeight.where(city_id: city.id, crime_type_id:key).first
			crime_trend << set_crime_trend(crime_type, value,city) if crime_type.id != 80 && city_crime_type.crime_weight > 0 && crime_type.display_name != nil
		end
		crime_trend
	end

	#  GENERATE SAFETY REPORT FOR GRID
	def generate_safety_report city_matrix, city, city_feature
		Rails.logger.info "Generate #{city.name} safety report"
		return city_matrix unless city_matrix
		city_matrix.each_with_index do |row_value, row_index|
			row_value.each_with_index do |col_value, col_index|
				col_value["daytimeSafetyReport"] = set_safety_rating(col_value["daytimeReport"],city_feature,row_index,col_index)
				col_value["darkSafetyReport"] = set_safety_rating(col_value["darkReport"],city_feature,row_index,col_index)
			end
		end
		Rails.logger.info "Done safety report"
		city_matrix
	end

	def generate_grid_avg_crime city_matrix, crime_list, city, city_feature
		Rails.logger.info "Generate #{city.name} grid average crime"
		return city_matrix unless city_matrix && crime_list.length > 0
		row_dimension = city_feature["rowDimension"]
		distance_btw_grid = city_feature["distanceBetweenCells"]
		crime_list.each do |crime|
			grid_index = get_row_col_index(crime.location.y,crime.location.x,city[:north_east].y,city[:south_west].x,row_dimension,distance_btw_grid)
			row_index = grid_index[:row]
			col_index = grid_index[:col]
			if row_index < city_matrix.length && col_index < city_matrix[0].length && row_index >= 0 && col_index >= 0
				crime_type = CrimeType.find(crime.crime_type_id)
				if crime.crime_day_time == 0
					city_matrix = set_annual_crime_trend(city_matrix,crime_type,"daytime_crime_trend",row_index, col_index,crime,city)
					city_matrix = prepare_annual_crime_report(city_matrix, "daytime_crime_reports", row_index, col_index, crime, city)
				else
					city_matrix = set_annual_crime_trend(city_matrix,crime_type,"dark_crime_trend",row_index, col_index,crime,city)
					city_matrix = prepare_annual_crime_report(city_matrix, "dark_crime_reports", row_index, col_index, crime, city)
				end
			end
		end

		city_matrix.each do |row|
			row.each do |col|
				col = set_annual_crime_avg(col, "daytime_crime_trend","daytime_annual_rating","daytime_annual_count")
				col = set_annual_crime_avg(col, "dark_crime_trend","dark_annual_rating","dark_annual_count")
			end
		end
		city_matrix
	end
	def generate_poi_list city_matrix, poi_list, city, city_feature
		Rails.logger.info "Generate #{city.name} poi list"
		return city_matrix unless city_matrix && poi_list.length > 0
		row_dimension = city_feature["rowDimension"]
		distance_btw_grid = city_feature["distanceBetweenCells"]

		poi_list.each do |poi|
			grid_index = get_row_col_index(poi.location.y,poi.location.x,city[:north_east].y,city[:south_west].x,row_dimension,distance_btw_grid)
			row_index = grid_index[:row]
			col_index = grid_index[:col]
			if row_index < city_matrix.length && col_index < city_matrix[0].length && row_index >= 0 && col_index >= 0
				if city_matrix[row_index][col_index]["poi_reports"].nil?
					city_matrix[row_index][col_index]["poi_reports"] = Hash.new
					city_matrix[row_index][col_index]["poi_reports"]["poi_list"] = Array.new
				end
				city_matrix[row_index][col_index]["poi_reports"]["poi_list"] << set_poi(poi)
			end
		end
		city_matrix
	end

	def set_poi poi
		poi_detail = Hash.new
		poi_detail[:id] = poi.id
		poi_detail[:name] = poi.name
		poi_detail[:poi_type] = poi.poi_type
		poi_detail[:latitude] = poi.location.y
		poi_detail[:longitude] = poi.location.x
		poi_detail
	end

	def prepare_annual_crime_report city_matrix, report_type, row_index, col_index, crime, city
		return city_matrix unless city_matrix && crime
		if city_matrix[row_index][col_index]["annual_report"]["#{report_type}"]
			city_matrix[row_index][col_index]["annual_report"]["#{report_type}"] << set_annual_crime_report(crime)
		else
			crime_reports = Array.new
			crime_reports << set_annual_crime_report(crime)
			city_matrix[row_index][col_index]["annual_report"]["#{report_type}"] = crime_reports
		end
		city_matrix
	end

	def set_annual_crime_trend city_matrix, crime_type, report_type, row_index, col_index,crime,city
		return city_matrix unless city_matrix
		crime_type_name = crime_type.name.strip.gsub(/\s/,'_').downcase
		if city_matrix[row_index][col_index]["annual_report"]
			annual_crime_trend = city_matrix[row_index][col_index]["annual_report"]["#{report_type}"]
			if annual_crime_trend
				if annual_crime_trend[crime_type_name]
					crime_type_report = annual_crime_trend[crime_type_name]
					crime_type_report["crimeCount"] += 1
					# crime_type_report["peakHour"] = set_peak_hour(crime_type_report["peakHour"],crime)
					annual_crime_trend[crime_type_name] = crime_type_report
				else
					crime_type_report = set_crime_trend(crime_type,1,city)
					# crime_type_report["peakHour"] = set_peak_hour(crime_type_report["peakHour"],crime)
					annual_crime_trend[crime_type_name] = crime_type_report
				end
			else
				annual_crime_trend = Hash.new
				crime_type_report = set_crime_trend(crime_type,1,city)
				# crime_type_report["peakHour"] = set_peak_hour(crime_type_report["peakHour"],crime)
				annual_crime_trend[crime_type_name] = crime_type_report
			end
		else
			annual_crime_trend = Hash.new
			crime_type_report = set_crime_trend(crime_type,1,city)
			# crime_type_report["peakHour"] = set_peak_hour(crime_type_report["peakHour"],crime)
			annual_crime_trend[crime_type_name] = crime_type_report
			city_matrix[row_index][col_index]["annual_report"] = Hash.new
		end
		# ap "row_index : #{row_index}"
		# ap "col_index : #{col_index}"
		# ap annual_crime_trend
		city_matrix[row_index][col_index]["annual_report"]["#{report_type}"] = annual_crime_trend
		city_matrix
	end

	def set_annual_crime_avg grid_report, report_type, annual_rating_type, annual_count_type
		return grid_report unless grid_report
		total_crime_weight = 0.0
		if grid_report["annual_report"]
			annual_crime_trend = grid_report["annual_report"]["#{report_type}"]
			if annual_crime_trend
				crime_count = 0
				annual_crime_trend.each do |key,value|
					crime_scale = calculate_logarithm_value(value["crimeWeight"])
					crime_weight = 0.0
					if value["violent"]
						if crime_scale >= 8
							crime_weight = value["crimeWeight"] * 1.5
						elsif crime_scale >= 5 && crime_scale < 8
							crime_weight = value["crimeWeight"] * 1.3
						elsif crime_scale >= 1 && crime_scale < 5
							crime_weight = value["crimeWeight"] * 1.1
						else
							crime_weight = value["crimeWeight"]
						end
					else
						crime_weight = value["crimeWeight"]
					end
					crime_count += value["crimeCount"]
					total_crime_weight += (value["crimeCount"] * crime_weight)
				end
				grid_report["annual_report"]["#{annual_rating_type}"] = total_crime_weight/crime_count
				grid_report["annual_report"]["#{annual_count_type}"] = crime_count
			else
				grid_report["annual_report"]["#{annual_rating_type}"] = 0.0
				grid_report["annual_report"]["#{annual_count_type}"] = 0.0
			end
		else
			grid_report["annual_report"] = Hash.new
			grid_report["annual_report"]["#{annual_rating_type}"] = 0.0
			grid_report["annual_report"]["#{annual_count_type}"] = 0.0

		end
		grid_report["annual_report"]["updated_at"] = DateTime.now
		grid_report
	end

	def analyze_grid_annual_rating city_matrix

		return city_matrix unless city_matrix
		city_matrix.each do |row|
			row.each do |col|
				col = set_safety_rating_by_annual_rating(col, "daytime_annual_rating", "daytimeSafetyReport") if col["daytimeCrimeTrend"].length == 0
				col = set_safety_rating_by_annual_rating(col, "dark_annual_rating", "darkSafetyReport") if col["darkCrimeTrend"].length == 0
			end
		end
		city_matrix
	end

	def set_safety_rating_by_annual_rating grid_report, annual_rating_type, safety_report_type
		annual_rating = grid_report["annual_report"]["#{annual_rating_type}"]
		# if annual_rating >= 64
			# ap grid_report["#{safety_report_type}"]["safetyRating"]
			# ap "Changed to LOW_SAFETY"
			# grid_report["#{safety_report_type}"]["safetyRating"] = "LOW_SAFETY"

		# elsif annual_rating >= 22 && annual_rating <= 63
		if annual_rating >= 22
			# ap grid_report["#{safety_report_type}"]["safetyRating"]
			# ap "Changed to MODERATE"
			grid_report["#{safety_report_type}"]["safetyRating"] = "MODERATE"
		end

		set_safe_or_unsafe_zone(grid_report, safety_report_type)

		grid_report
	end

	def set_peak_hour peak_hour_hash, crime
		return unless crime
		peak_hour_hash = Hash.new if peak_hour_hash.nil?
		date_time = crime.occurred_at
		if peak_hour_hash[date_time.hour]
			peak_hour_hash[date_time.hour] += 1
		else
			peak_hour_hash[date_time.hour] = 1
		end
		peak_hour_hash
	end

	def store_as_cache city, city_matrix,city_feature, old_report
		redis = RedisService.new
		city_name = city.name.gsub(/\s/,'_').downcase
		city_matrix.each_with_index do |row, row_index|
			row.each_with_index do |col, col_index|
				key = APP_CONFIG['city_crime_grid'] + city_name + "_" + row_index.to_s + "_" + col_index.to_s
				key += APP_CONFIG['history_report'] if old_report
				redis.set_value(key,col)
			end
		end

		redis.set_value(APP_CONFIG['city_grid_feature'] + city_name, city_feature)

	end

	def set_safety_rating crime_list, city_feature, row_index, col_index
		grid_weight = 0.0
		grid_crime_count = 0
		safety_report = Hash.new
		crime_hash = Hash.new
		crime_list.each do |crime|

			crime_scale = calculate_logarithm_value(crime["crimeWeight"])
			crime_weight = 0.0
			if crime["violent"]
				if crime_scale >= 8
					crime_weight = crime["crimeWeight"] * 1.5
				elsif crime_scale >= 5 && crime_scale < 8
					crime_weight = crime["crimeWeight"] * 1.3
				elsif crime_scale >= 1 && crime_scale < 5
					crime_weight = crime["crimeWeight"] * 1.1
				else
					crime_weight = crime["crimeWeight"]
				end
			else
				crime_weight = crime["crimeWeight"]
			end

			grid_weight += crime_weight
			grid_crime_count += 1
			if crime_hash["#{crime["crimeType"].upcase}"]
				crime_hash["#{crime["crimeType"].upcase}"] << crime
			else
				crime_objects = Array.new
				crime_objects << crime
				crime_hash["#{crime["crimeType"].upcase}"] = crime_objects
			end
		end

		safety_report["crimeDataHashMapByCrimeType"] = crime_hash
		grid_weight = grid_weight/crime_list.length if crime_list.length > 0

		if grid_weight >= 64
			safety_report["safetyRating"] = "LOW_SAFETY"
		elsif grid_weight >= 22 && grid_weight <= 63
			safety_report["safetyRating"] = "MODERATE"
		else
			safety_report["safetyRating"] = "MODERATELY_SAFE"
		end

		safety_report["crimeReportStartDate"] = city_feature["crimeReportStartDate"]
		safety_report["crimeReportEndDate"] = city_feature["crimeReportEndDate"]
		safety_report["rowIndex"] = row_index
		safety_report["colIndex"] = col_index
		safety_report["radius"] = city_feature["distanceBetweenCells"]
		safety_report["totalCrimeCount"] = grid_crime_count
		safety_report["averageCrimeCount"] = grid_weight.nil? ? 0 : grid_weight
		safety_report
	end

	def set_crime_trend crime_type, value,city
		crime_type_name = crime_type.display_name.nil? ? crime_type.name : crime_type.display_name
		city_crime_type = CitiesCrimeTypeWeight.where(city_id: city.id, crime_type_id: crime_type.id).first
		return {
			"crimeType" => crime_type_name.strip.downcase,
			"crimeCount" => value,
			"crimeWeight" => city_crime_type.crime_weight,
			"violent" => crime_type.violent
		}
	end

	def set_crime_report crime_data
		return unless crime_data
		crime_type = CrimeType.find(crime_data.crime_type_id)
		city_crime_type = CitiesCrimeTypeWeight.where(city_id: @city.id, crime_type_id: crime_data.crime_type_id).first
		return {
			"id" => crime_data.id,
			"crimeCaseId" => crime_data.crime_case_id,
			"crimeType" => crime_type.name.strip,
			"crimeTypeId" => crime_type.id,
			"occurredAt" => crime_data.occurred_at,
			"latitude" => crime_data.location.y,
			"longitude" => crime_data.location.x,
			"crimeDayTime" => crime_data.crime_day_time == 0 ? 'DAYTIME' : 'DARK',
			"ward" => crime_data.ward,
			"communityArea" => crime_data.community_area,
			"district" => crime_data.district,
			"block" => crime_data.block,
			"crimeWeight" => city_crime_type.crime_weight,
			"displayName" => crime_type.display_name,
			"violent" => crime_type.violent
		}
	end

	def set_annual_crime_report crime_data
		return unless crime_data
		crime_type = CrimeType.find(crime_data.crime_type_id)
		city_crime_type = CitiesCrimeTypeWeight.where(city_id: @city.id, crime_type_id: crime_data.crime_type_id).first
		return {
			"crime_type" => crime_type.name.strip,
			"crime_type_id" => crime_type.id,
			"occurred_at" => crime_data.occurred_at,
			"latitude" => crime_data.location.y,
			"longitude" => crime_data.location.x,
			"crime_day_time" => crime_data.crime_day_time == 0 ? 'DAYTIME' : 'DARK',
			"crime_weight" => city_crime_type.crime_weight
		}
	end

	def set_user_rating_report rating_data
		return {
			"id" => rating_data.id,
			"crimeStreetsID" => rating_data.crime_streets_id,
			"latitude" => rating_data.latitude,
			"longitude" => rating_data.longitude,
			"userStreetSafetyRating" => rating_data.user_street_safety_rating,
			"userRatingTime" => rating_data.user_rating_time,
			"userid" => rating_data.userid,
			"city" => rating_data.city,
			"state" => rating_data.state,
			"country" => rating_data.country,
			"postcode" => rating_data.postcode,
			"accuracy" => rating_data.accuracy

		}
	end

	def set_coordinate latitude, longitude
		geo = GeoFormula.new
		grid_coordinate = Hash.new
		center_coordinate = geo.project_point(latitude, longitude, 135.0, Math.sqrt(2) * 0.125)
		btm_right_coordinate = geo.project_point(latitude, longitude, 135.0, Math.sqrt(2) * 0.25)
		all_coordinates = {
			"centerLatitude" => center_coordinate[:lat],
			"centerLongitude" => center_coordinate[:lng],
			"topLeftLatitude" => latitude,
			"topLeftLongitude" => longitude,
			"btmRightLatitude" => btm_right_coordinate[:lat],
			"btmRightLongitude"=> btm_right_coordinate[:lng],
			"generateDetails" => true
		}
		grid_coordinate["crimeCoordinate"] = all_coordinates
		grid_coordinate = set_reports_to_array(grid_coordinate)
		# ap grid_coordinate
		grid_coordinate
	end

	def set_reports_to_array grid_coordinate
		grid_coordinate["daytimeReport"] = Array.new
		grid_coordinate["darkReport"] = Array.new
		grid_coordinate["crimeStreetsRatingVO"] = Array.new
		grid_coordinate["userStreetSafetyRatingVO"] = Array.new
		grid_coordinate["daytimeCrimeTrend"] = Array.new
		grid_coordinate["darkCrimeTrend"] = Array.new
		grid_coordinate["daytimeSafetyReport"] = Array.new
		grid_coordinate["darkSafetyReport"] = Array.new
		grid_coordinate
	end

	def set_safe_or_unsafe_zone grid_report, safety_report_type
		grid_center_coord = RGeo::Geos.factory(srid: 4326).point(grid_report['crimeCoordinate']['centerLongitude'], grid_report['crimeCoordinate']['centerLatitude'])
		@@zones.each do |zone|
			if grid_center_coord.within?(zone.area)
				if zone.zone_type == "LOW_SAFETY" || zone.zone_type == "AVOID"
					if zone.dark? && safety_report_type == "darkSafetyReport"
						grid_report["darkSafetyReport"]["safetyRating"] = "LOW_SAFETY"
					elsif zone.daytime? && safety_report_type == "daytimeSafetyReport"
						grid_report["daytimeSafetyReport"]["safetyRating"] = "LOW_SAFETY"
					end
				elsif zone.zone_type == "MODERATELY_SAFE"
					grid_report["#{safety_report_type}"]["safetyRating"] = "MODERATELY_SAFE"
				end
			end
		end
	end

	def send_msg city_id, msg
	    conn = Bunny.new(host: APP_CONFIG["rabbitmq_host"], port: APP_CONFIG["rabbitmq_port"])
	    conn.start
	    channel = conn.create_channel
	    queue  = channel.queue(APP_CONFIG["rabbitmq_queue_name"])
	    queue.publish("delta_#{city_id}_" + msg)
	    conn.stop
	end

	def calculate_logarithm_value crime_weight
      return 1 unless crime_weight > 0.0
      harmful_level = (Math.log2(crime_weight) )/ 0.75
      if harmful_level - harmful_level.floor > 0.5
        return harmful_level.ceil
      else
        return harmful_level.floor
      end
    end

end
