class AnalyseFormula


	def correlation_coefficient type_1, type_2

		# Formula
		#  Sxx = (sum of square x) - (sum of x square)/n
		#  Syy = (sum of square y) - (sum of y square)/n
		#  Sxy = (sum of product x & y) - ((sum of x) * (sum of y))/n
		#  p = Sxy / ( Sxx * Syy)

		# Sum of type 1
		sum_type_1 = 0
		sum_type_2 = 0
		size_of_crime_type = type_1.length
		sum_of_square_type_1 = 0
		sum_of_square_type_2 = 0
		product_of_sum_type_1_2 = 0
		product_of_sum = 0
		correlation = 0
		type_1.each do |key,value|
			sum_type_1 += value.to_i
			sum_type_2 += type_2[key].to_i
			sum_of_square_type_1 += value.to_i**2
			sum_of_square_type_2 += type_2[key].to_i**2
			product_of_sum += value.to_i * type_2[key].to_i
		end

		sxx = sum_of_square_type_1 - (sum_type_1**2)/size_of_crime_type
		syy = sum_of_square_type_2 - (sum_type_2**2)/size_of_crime_type
		sxy = product_of_sum - (sum_type_1 * sum_type_2)/size_of_crime_type

		correlation = sxy / Math.sqrt(sxx * sxy)
		correlation
	end

	def standard_deviation report
		p "standard_deviation"
		stdev = 0.0
		if(report != nil)
			report_size = report.size.to_f
			mean = 0.0
			total_number = 0.0
			report.each do |k,v|
				total_number += v.to_f
			end
			mean = total_number / report_size
			ap mean
			temp_value = 0.0
			report.each do |k,v|
				temp_value += (v.to_f - mean)**2
			end
			stdev = Math.sqrt((1/n.to_f) * temp_value)
		end
		stdev
	end

	def average_value report
		mean = 0.0
		if(report != nil)
			report_size = report.size.to_f
			total_number = 0.0
			report.each do |key,value|
				value.each do |k,v|
					total_number += v.to_f
				end
			end
			mean = total_number / report_size
		end
		mean
	end

	# Calculate Local Maximum based on the report
	# report pass in as Hash
	def local_max report, avg_point
		local_max_list = []
		temp_local_max = 0.0
		report.each do |key,value|
			if(value.to_f >= avg_point)
				if(value.to_f <= temp_local_max)
					local_max_list << {
									"max_point" => temp_local_max
								}
				end
				temp_local_max = value.to_f
			else
				if(temp_local_max >= avg_point)
					local_max_list << {
									"max_point" => temp_local_max
								}
					temp_local_max = value.to_f
				end
				
			end
		end
		local_max_list
	end

	# Calculate Local Minimum based on the report
	# report pass in as Hash
	def local_min report, avg_point
		local_min_list = []
		temp_local_min = 0.0
		report.each do |key,value|
			if(temp_local_min == 0.0)
				if(value <= avg_point)
					temp_local_min = value
				else
					temp_local_min = avg_point
				end
			else
				if(value <= avg_point)
					if(temp_local_min >= value)
						temp_local_min = value
					else
						if(key + 1 < report.size)
							if(temp_local_min < report[key + 1])
								local_min_list << {
									"min_point" => temp_local_min
								}
							else
								temp_local_min = value
							end
						else
							local_min_list << {
									"min_point" => temp_local_min
								}
						end
					end
				end
			end
		end
		local_min_list
	end
end