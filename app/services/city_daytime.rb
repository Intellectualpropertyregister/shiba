class CityDayTime

	def get_city_time city_name, city_country
		daytime = Hash.new
		target_zone = TZInfo::Country.get("#{city_country}").zone_identifiers

		target_zone.each do |zone|
			time = ActiveSupport::TimeZone["#{zone}"].at(Time.now)
			if time.hour >= 3 && time.hour <= 8
				daytime[:start_time] = "#{Date.today} 03:00:00"
				daytime[:end_time] = "#{Date.today} 08:59:00"
				daytime[:daytime] = "MORNING"
			elsif time.hour >= 9 && time.hour <= 17
				daytime[:start_time] = "#{Date.today} 09:00:00"
				daytime[:end_time] = "#{Date.today} 17:59:00"
				daytime[:daytime] = "DAYTIME"
			elsif time.hour >= 18 && time.hour <= 23
				daytime[:start_time] = "#{Date.today} 18:00:00"
				daytime[:end_time] = "#{Date.today} 23:59:00"
				daytime[:daytime] = "NIGHT"
			elsif time.hour >= 0 && time.hour <= 2
				daytime[:start_time] = "#{Date.today} 00:00:00"
				daytime[:end_time] = "#{Date.today} 02:59:00"
				daytime[:daytime] = "NIGHT"
			end
		end
		daytime
	end


end