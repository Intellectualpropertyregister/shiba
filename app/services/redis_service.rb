class RedisService
	def get_value key
		response = $redis.get(key)
		return JSON.parse(response) if response
	end

	def set_value key, value
		$redis.set(key,value.to_json)
	end

	def del_value key
		$redis.del(key)
	end
end