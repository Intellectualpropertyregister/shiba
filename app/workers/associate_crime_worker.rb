require 'analyse_formula'
require 'redis_service'
class AssociateCrimeWorker
	include Sidekiq::Worker
	CITY_GRID_FEATURES = APP_CONFIG['city_grid_feature']
	DYNAMODB_TABLE = APP_CONFIG['dynamodb_table']

	THEFT = APP_CONFIG['target_crime_theft']
	BATTERY = APP_CONFIG['target_crime_battery']
	NARCOTICS = APP_CONFIG['target_crime_narcotics']
	VEHICLE_THEFT = APP_CONFIG['target_crime_vehicle_theft']
	ASSAULT = APP_CONFIG['target_crime_assault']
	WEAPONS_VIOLATION = APP_CONFIG['target_crime_weapons_violation']
	HOMICIDE = APP_CONFIG['target_crime_homicide']
	SEX_OFFENSE = APP_CONFIG['target_crime_sex_offense']
	FORCE_SEX_OFFENSE = APP_CONFIG['target_crime_force_sex_offense']

	def perform city_id

		crime_type_map = Hash.new
		result = Hash.new
		@city = City.search(id_eq: city_id).result
		city_name = @city[0].name.downcase

		city_grid_feature = get_crime_feature(city_name)
		crime_report_start_date = Time.at(city_grid_feature["crimeReportStartDate"].to_i/1000)
		crime_report_end_date = Time.at(city_grid_feature["crimeReportEndDate"].to_i/1000)
		@crime_type = CrimeType.all
		@crime_type.each do |crime|
			# ap crime.name.to_s +  " NOM~ NOM~ NOM~ NOM~"
			temp_hash = Hash.new
			@crime_data = CrimeData.search(crime_type_id_eq: crime.id).result.group_by{|u| u.occurred_at.month}
			@crime_data.each do |key,value|
				temp_hash[key] = value.size
			end
			month = 1
			while month <= 12 do
				if(temp_hash[month].nil?)
					temp_hash[month] = 0
				end
				month += 1
			end

			crime_type_map[crime.name.downcase] = temp_hash
		end

		theft = calculate_correlation(crime_type_map,THEFT)
		battery = calculate_correlation(crime_type_map,BATTERY)
		narcotics = calculate_correlation(crime_type_map,NARCOTICS)
		vehicle_theft = calculate_correlation(crime_type_map,VEHICLE_THEFT)
		assault = calculate_correlation(crime_type_map,ASSAULT)
		weapons_violation = calculate_correlation(crime_type_map,WEAPONS_VIOLATION)
		homicide = calculate_correlation(crime_type_map,HOMICIDE)
		sex_offense = calculate_correlation(crime_type_map,SEX_OFFENSE)
		force_sex_offense = calculate_correlation(crime_type_map,FORCE_SEX_OFFENSE)

	end

	private

	def get_crime_feature city_name
		redis = RedisService.new
		key = CITY_GRID_FEATURES + city_name
		feature = redis.get_value(key)
		feature
	end

	def calculate_correlation crime_type_list, target_crime_type
		target_crime_correlation = Hash.new
		analyse = AnalyseFormula.new
		if(crime_type_list[target_crime_type].nil?)
		end
		crime_type_list.each do |key,value|
			if (key != target_crime_type)
				target_crime_correlation[key] = analyse.correlation_coefficient(crime_type_list[target_crime_type],value)
			end
		end
		target_crime_correlation
	end



end
