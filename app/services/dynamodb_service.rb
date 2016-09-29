class DynamodbService

	def get_value table_name, key
		value = $dynamodb.get_item(:table_name => "#{table_name}",
		 :key => {:Key => "#{key}"},
		 :return_consumed_capacity => "TOTAL")
		if(value.consumed_capacity.capacity_units > 10.0)
			sleep(1)
		end
		value
	end

	def set_value table_name, key, value
		response = $dynamodb.put_item(:table_name => "#{table_name}",
			:item => {:Key => "#{key}",
			"#{key}" => value},
			:return_consumed_capacity => "TOTAL")
		if(response != nil)
			if(response.consumed_capacity.capacity_units > 10.0)
				sleep(1)
			end
		end
	end

	def delete_value table_name, key
		response = $dynamodb.delete_item(:table_name => "#{table_name}",
			:key => {:Key => "#{key}"},
			:return_consumed_capacity => "TOTAL")
		if(response != nil)
			if(response.consumed_capacity.capacity_units > 10.0)
				sleep(1)
			end
		end
	end

	def update_value table_name,key,value,update_key
		# ap key
		# ap value
		response = $dynamodb.update_item(:table_name => "#{table_name}",
			:key => {:Key => "#{key}"},
			:update_expression => "SET #attr_name = :attr_value",
			:expression_attribute_names => {"#attr_name" => update_key},
			:expression_attribute_values => {":attr_value" => value},
 			:return_consumed_capacity => "TOTAL",
			:return_values => "ALL_NEW")
		# ap response
		if(response != nil)
			if(response.consumed_capacity.capacity_units > 10.0)
				sleep(1)
			end
		end
	end

end