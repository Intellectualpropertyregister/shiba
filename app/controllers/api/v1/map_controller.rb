require 'redis_service'
class Api::V1::MapController < ApplicationController

	def visualize_current
		redis = RedisService.new
		result = Hash.new
		if params[:city_name] && params[:map_name]
			report = nil
			@city = City.search(name_cont: params[:city_name]).result
			if @city
				city_name = @city[0].name.downcase
				if params[:crime_day_time]
					if params[:crime_day_time] == "daytime"
						report = redis.get_value("#{APP_CONFIG["cache_daytime_crime_matrix"]}"+ city_name)
					elsif params[:crime_day_time] == "dark"
						report = redis.get_value("#{APP_CONFIG["cache_dark_crime_matrix"]}"+ city_name)
					else
						report = redis.get_value("#{APP_CONFIG["cache_daytime_crime_matrix"]}"+ city_name)
					end
				else
					time_zone = TZInfo::Country.get("#{@city[0].country}").zone_identifiers
					start_time = nil
					end_time = nil
					time_zone.each do |zone| 
						if zone.include? @city[0].name
							time = ActiveSupport::TimeZone["#{zone}"].at(Time.now)
							ap time
							if time.hour >= 7 && time.hour <= 18
								report = redis.get_value("#{APP_CONFIG["cache_daytime_crime_matrix"]}"+ city_name)
							elsif time.hour >= 19 && time.hour <= 23
								report = redis.get_value("#{APP_CONFIG["cache_dark_crime_matrix"]}"+ city_name)
							elsif time.hour >= 0 && time.hour <= 6
								report = redis.get_value("#{APP_CONFIG["cache_dark_crime_matrix"]}"+ city_name)
							end
						end
					end
				end
			end
			result["report"] = report
			result["map"] = params[:map_name]
		end

		respond_to do |format|
	    	format.html 
	      	format.json { render :json => result }
	    end
	end

	def tips
		tips_report = []
		@tips = Tip.all
		@tips.each do |tip|
			tips_report << {
				"description" => tip[:description],
				"latitude" => tip[:location].y,
				"longitude" => tip[:location].x
			}
		end
		# puts tips_report
		respond_to do |format|
	    	format.html 
	      	format.json { render :json => tips_report }
	    end
	end
end