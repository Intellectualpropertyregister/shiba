require 'analyse_formula'
class Api::V1::ReportsController  < ApplicationController
	def wards_report
		# ap "wards_report"
		final_report = []
		@q = CrimeData.search(crime_type_id_eq: params["crime_type_id_eq"],
			occurred_at_gteq: params["occurred_at_gteq"],
			occurred_at_lteq: params["occurred_at_lteq"],
			ward_eq: params["ward_eq"]).result

		ward_report = generate_wards_report(@q,true)
		ward_report.sort.map do |key, value|
			final_report << {
				"month" => key,
				"morning" => value["morning_delta"],
				"daytime" => value["daytime_delta"],
				"night" => value["night_delta"]
			}
		end
		
		# ap final_report
		respond_to do |format|
	    	format.html 
	      format.json { render :json => final_report }
	    end
	end

	def crime_type_report
		final_report = []
		local_max_value = Hash.new
		@q = CrimeData.search(crime_type_id_eq: params["crime_type_id_eq"],
			occurred_at_gteq: params["occurred_at_gteq"],
			occurred_at_lteq: params["occurred_at_lteq"],
			ward_eq: params["ward_eq"]).result
		ward_report = generate_wards_report(@q,true)
		spike_detection = AnalyseFormula.new
		avg = AnalyseFormula.new.average_value(ward_report)
		# ap avg
		
		ward_report.sort.map do |key, value|
			final_report << {
				"month" => key,
				"total" => value["morning_delta"] + value["daytime_delta"] + value["night_delta"]
			}
			local_max_value[key] = value["morning_delta"] + value["daytime_delta"] + value["night_delta"]
		end
		local_max_value = spike_detection.local_max(local_max_value,avg)
		# ap local_max_value
		# ap final_report

		respond_to do |format|
	    	format.html 
	      format.json { render :json => final_report }
	    end
	end

	def narcotics_report
		# ap "narcotics report"
		final_report = []
		ward_id = params["ward_eq"]
		occurred_at_gteq = params["occurred_at_gteq"]
		occurred_at_lteq = params["occurred_at_lteq"]
		@crime_data = CrimeData.search(occurred_at_gteq: params["occurred_at_gteq"],
			occurred_at_lteq: params["occurred_at_lteq"],
			ward_eq: params["ward_eq"]).result
		@crime_data = filter_crime(@crime_data)
		final_report = generate_wards_report(@crime_data,false)
		# ap final_report
		respond_to do |format|
	    	format.html 
	      format.json { render :json => final_report }
	    end
	end
	
	private

	def filter_crime crime_data
		filtered_crime = []
		crime_data.each do |c|
			if(c[:crime_type_id] == 34 || c[:crime_type_id] == 6 ||
				c[:crime_type_id] == 23 || c[:crime_type_id] == 33 ||
				c[:crime_type_id] == 57 || c[:crime_type_id] == 26 ||
				c[:crime_type_id] == 2 || c[:crime_type_id] == 4 ||
				c[:crime_type_id] == 70 || c[:crime_type_id] == 60 ||
				c[:crime_type_id] == 44)
				filtered_crime << c
			end
		end
		filtered_crime
	end

	def generate_wards_report crime_list, daytime
		
		wards = Hash.new
		crime_in_month = Hash.new
		# generate month
		# ap crime_list

		crime_list.each do |c|
			# ap c
			if(wards[c[:occurred_at].month] != nil)
				report = wards[c[:occurred_at].month]
				if(daytime)
					report = get_report_by_daytime(c,report)
				else
					report = get_narcotics_report(c,report)
				end
			else
				if(daytime)
					report = get_report_by_daytime(c,nil)
				else
					report = get_narcotics_report(c,report)
				end
			end
			wards[c[:occurred_at].month] = report
		end

		crime_type_hash = Hash.new
		crime_name_hash = Hash.new
		@crime_type = CrimeType.all
		# ap @crime_type
		@crime_type.each do |c|
			crime_type_hash[c[:id]] = c[:crime_weight]
			crime_name_hash[c[:id]] = c[:name]
		end
		# ap ctype
		if(daytime)
			wards = calculate_weight_by_daytime(wards,crime_type_hash)
		else
			# ap wards
			wards = calculate_report(wards,crime_type_hash,false)
			wards = finalize_narcotics_report(wards,crime_name_hash)
		end
		# ap wards
		wards
	
	end 

	def finalize_narcotics_report report,crime_name
		# ap "finalize"
  		new_report = []
  		report.sort.map do |key, value|
			new_report << {
				"month" => key,
				crime_name[70].to_s => value[70].nil? ? 0.0 : value[70],
				crime_name[6].to_s => value[6].nil? ? 0.0 : value[6],
				crime_name[4].to_s => value[4].nil? ? 0.0 : value[4],
				crime_name[23].to_s => value[23].nil? ? 0.0 : value[23],
				crime_name[60].to_s => value[60].nil? ? 0.0 : value[60],
				crime_name[34].to_s => value[34].nil? ? 0.0 : value[34],
				crime_name[2].to_s => value[2].nil? ? 0.0 : value[2],
				crime_name[33].to_s => value[33].nil? ? 0.0 : value[33],
				crime_name[57].to_s => value[57].nil? ? 0.0 : value[57],
				crime_name[26].to_s => value[26].nil? ? 0.0 : value[26],
				crime_name[44].to_s => value[44].nil? ? 0.0 : value[44]
			}
  		end
  		new_report
	end

	def get_narcotics_report crime,report
		if(report == nil)
			report = Hash.new
		else
			if(report[crime[:crime_type_id]] != nil)
				count = report[crime[:crime_type_id]]
				report[crime[:crime_type_id]] = count + 1
			else
				report[crime[:crime_type_id]] = 1
			end
		end

		report
	end

	def get_report_by_daytime crime, report
		# ap "getReport"
		if(report == nil)
			report = {}
			morning_crime = Hash.new
			daytime_crime = Hash.new
			night_crime = Hash.new
		else
			if(report["morning_crime"] != nil)
				morning_crime = report["morning_crime"]
			else
				morning_crime = Hash.new
			end

			if(report["daytime_crime"] != nil)
				daytime_crime = report["daytime_crime"]
			else
				daytime_crime = Hash.new
			end

			if(report["night_crime"] != nil)
				night_crime = report["night_crime"]
			else
				night_crime = Hash.new
			end
		end

		if(crime[:crime_day_time] == 0)
			# MORNING
			if(morning_crime[crime[:crime_type_id]] != nil)
				# ap "if"
				count = morning_crime[crime[:crime_type_id]]
				morning_crime[crime[:crime_type_id]] = count + 1
			else
				# ap "else"
				morning_crime[crime[:crime_type_id]] = 1
				# ap c[:crime_type] + " with " +  morning_crime[c[:crime_type]].to_s
			end
		elsif (crime[:crime_day_time] == 1)
			# DAYTIME
			if(daytime_crime[crime[:crime_type_id]] != nil)
				count = daytime_crime[crime[:crime_type_id]]
				daytime_crime[crime[:crime_type_id]] = count + 1
			else
				daytime_crime[crime[:crime_type_id]] = 1
			end
		else
			# NIGHT
			if(night_crime[crime[:crime_type_id]] != nil)
				count = night_crime[crime[:crime_type_id]]
				night_crime[crime[:crime_type_id]] = count + 1
			else
				night_crime[crime[:crime_type_id]] = 1
			end
		end 

		report = {
			"morning_crime" => morning_crime,
			"daytime_crime" => daytime_crime,
			"night_crime" => night_crime
		}
		report
	end

	def calculate_weight_by_daytime wards_report, crime_types
		# ap "calculate_weight"
		# ap wards_report
		report = Hash.new
		wards_report.each do|key,value|
			morning_report = value["morning_crime"]
			morning_delta = calculate_report(morning_report,crime_types,true)

			daytime_report = value["daytime_crime"]
			daytime_delta = calculate_report(daytime_report,crime_types,true)

			night_report = value["night_crime"]
			night_delta = calculate_report(night_report,crime_types,true)

			delta = {
				"morning_delta" => morning_delta,
				"daytime_delta" => daytime_delta,
				"night_delta" => night_delta 
			}

			report[key] = delta
			
		end
		# ap report
		report
	end


	def calculate_report report, crime_types, daytime
		total_crime_weight = 0.0
		crime_frequency = 0.0
		delta = 0.0
		# ap report
		report.each do |key, value|
			if(daytime)
				weight = crime_types[key]
				if(weight != nil)
					total_crime_weight = total_crime_weight + ( weight * value)
					crime_frequency = crime_frequency + value
				end
			else
				value.each do |key,val|
					weight = crime_types[key]
					if(weight != nil)
						value[key] = (val)
					end
				end
				report[key] = value
			end
		end
		# ap "Total Crime Weight : #{total_crime_weight} with frequency of #{crime_frequency}"
		if(total_crime_weight != 0 && crime_frequency != 0)
				delta = total_crime_weight
		end
		if(daytime)
			delta
		else
			report
		end
	end
end