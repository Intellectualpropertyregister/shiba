
class RestcallService


	def post_call api_url, params
		uri = URI.parse(api_url)
		request = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
		request.body = "#{params}"
		response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  			http.request(request)
  		end

  		case response
  		when Net::HTTPSuccess, Net::HTTPRedirection
  			# ap "Success"
  			# ap response
  		else
  			# ap "Failed"
  			# ap response
  		end

	end

	def get_call api_url
		limit = 5
		raise ArgumentError, 'Error! Too many HTTP redirects' if limiit == 0
		uri = URI.parse(api_url)
		response = Net::HTTP.get(uri)

		case response
		when Net::HTTPSuccess then
			# ap "Success"
			# ap response
		when Net::HTTPRedirection then
			location = reponse['location']
			# ap "Redirecting to #{location}" 
			fetch(location,limit - 1)
		else
			# ap "Failed"
			# ap response
		end
	end
end