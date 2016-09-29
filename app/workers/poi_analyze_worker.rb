class PoiAnalyzeWorker
    include Sidekiq::Worker

    def perform city_id
        puts "POI Analyze Worker"
        @city = City.find(city_id)
        city_name = @city.name.gsub(" ","_").downcase
        result = Array.new
        reports = get_reports(city_name)
        reports[:grid_report].each do |row_index,col_grid|
            col_grid.each do |col_index,grid|
                if grid["poi_reports"] && grid["annual_report"]
                    daytime_crime_trend = grid["annual_report"]["daytime_crime_reports"]
                    dark_crime_trend = grid["annual_report"]["dark_crime_reports"]
                    poi_list = grid["poi_reports"]["poi_list"]
                    compare_distance(grid, dark_crime_trend, poi_list, "dark",col_index, row_index) if dark_crime_trend
                    compare_distance(grid, daytime_crime_trend, poi_list, "daytime",col_index, row_index) if daytime_crime_trend
                end
            end
        end
        puts "END"
    end



    private
    # Calculate the distance between poi and crime
    def compare_distance grid, crime_trend, poi_list, report_type, col_index, row_index
        report = Hash.new
        if grid["poi_reports"]["#{report_type}_crime_poi"]
            report_created_at = DateTime.parse(grid["poi_reports"]["#{report_type}_crime_poi"]["created_at"])
            if report_created_at.day - DateTime.now.day > 1
                grid["poi_reports"]["#{report_type}_crime_poi"]["created_at"] = DateTime.now
                grid["poi_reports"]["#{report_type}_crime_poi"]["report"] = Hash.new
            else
                report = grid["poi_reports"]["#{report_type}_crime_poi"]["report"]
            end
        else
            report = Hash.new
            report["created_at"] = DateTime.now
            report["report"] = Hash.new
            grid["poi_reports"]["#{report_type}_crime_poi"] = report
        end
        crime_poi_result = Array.new
        crime_trend.each do |crime|
            # ap crime
            crime_poi_distance = 0.0
            crime_poi_details = Hash.new
            poi_list.each do |poi|
                distance = calculate_distance(crime,poi)
                crime_poi_distance = distance if crime_poi_distance == 0.0
                # ap "distance : #{distance} , crime_poi_distance : #{crime_poi_distance}"
                if distance <= crime_poi_distance
                    crime_poi_details["crime_type"] = crime["crime_type"]
                    crime_poi_details["crime_type_id"] = crime["crime_type_id"]
                    crime_poi_details["crime_weight"] = crime["crime_weight"]
                    # crime_poi_details["occurred_at"] = crime["occurred_at"]
                    crime_poi_details["poi"] = poi["name"]
                    crime_poi_details["poi_id"] = poi["id"]
                    crime_poi_details["poi_type"] = poi["poi_type"]
                    crime_poi_details["distance"] = distance
                    crime_poi_distance = distance
                end
            end
            crime_poi_result << crime_poi_details
        end
        filter_result(crime_poi_result, grid["annual_report"],row_index, col_index,report_type)
    end

    def calculate_distance crime, poi
        return GeoFormula.new.distance(crime["latitude"], crime["longitude"], poi["latitude"], poi["longitude"]).round(2)
    end


    def get_reports city_name

		redis = RedisService.new
		reports = Hash.new
		grid_report = Hash.new

		# Get city feature
		city_feature_key = APP_CONFIG['city_grid_feature'] + city_name
		city_feature = redis.get_value(city_feature_key)
		# Get current grid_reports
		unless city_feature.blank?
			row_dimension = city_feature["rowDimension"].nil? ? 0 : get_grid_dimensions(city_feature, "row")
			col_dimension = city_feature["colDimension"].nil? ? 0 : get_grid_dimensions(city_feature, "col")
			if row_dimension > 0 && col_dimension > 0

				(0..row_dimension).each do |row_index|
                    col_grid = Hash.new

					(0..col_dimension).each do |col_index|
						# Current Grid Report
						grid_report_key = generate_key(APP_CONFIG['city_crime_grid'],city_name,row_index,col_index)
						grid_report_value = redis.get_value(grid_report_key)
						# Rails.logger.info "current_grid_report_key : #{grid_report_value}"

						col_grid[col_index] = grid_report_value if grid_report_value

					end
					grid_report[row_index] = col_grid
				end
			end
		end

		reports[:city_feature] = city_feature.nil? ? Hash.new : city_feature
		reports[:grid_report] = grid_report
		reports
	end

    def generate_key key_base, city_name, row_index, col_index
		return key_base + city_name + "_" + row_index.to_s + "_" + col_index.to_s
	end

    def get_grid_dimensions(report, dimension)
		return report["#{dimension}Dimension"].to_i - 1
	end

    # Check crime clustered in poi
    def filter_result result_list, annual_report,row_index, col_index, report_type
        # ap "filter_result"
        poi_list = Hash.new
        result_list.each do |report|
            if report["crime_weight"] > 0
                if poi_list["poi_#{report["poi"]}"]
                    if poi_list["poi_#{report["poi"]}"]["#{report["crime_type"]}"]
                        poi_list["poi_#{report["poi"]}"]["#{report["crime_type"]}"]["count"] += 1
                    else
                        poi_list["poi_#{report["poi"]}"]["#{report["crime_type"]}"] = new_crime_poi_details(report)
                    end
                else
                    poi_list["poi_#{report["poi"]}"] = Hash.new
                    poi_list["poi_#{report["poi"]}"]["#{report["crime_type"]}"] = new_crime_poi_details(report)
                end
            end
        end

        if annual_report["#{report_type}_annual_count"] > 10
            threshold = (annual_report["#{report_type}_annual_count"] * 0.1).ceil
            # ap "Crime Count : #{annual_report["#{report_type}_annual_count"]}"
            # ap "Threshold (10%) : #{threshold}"
            # ap poi_list
            poi_list.each do |key,value|
                value.each do |k,v|
                    if v["count"] > threshold
                        # CREATE notification
                        report = Hash.new
                        report[:row_index] = row_index
                        report[:col_index] = col_index
                        report[:crime_type] = k
                        report[:crime_count] = v["count"]
                        report[:poi] = key
                        report[:poi_id] = v["poi_id"]
                        report[:total_number_of_annual_crime] = annual_report["#{report_type}_annual_count"]
                        if annual_report["#{report_type}_annual_count"] > 0
                            create_notification("POI Error", report, true)
                        else
                            create_notification("POI Error", report, false)
                        end
                    end
                end
            end
        end
    end

    def new_crime_poi_details report
        details = Hash.new
        details["count"] = 1
        details["distance"] = report["distance"]
        details["crime_type_id"]= report["crime_type_id"]
        details["poi_id"] = report["poi_id"]
        details
    end
    #
    def create_notification error_msg, error_code, annual_report
        Notification.create(title: "POI-Cluster", error_msg: error_msg, error_code: error_code, reviewed:false, annual_report: annual_report)
    end
end
