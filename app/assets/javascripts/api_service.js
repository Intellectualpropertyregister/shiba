function rest_get_method(api_url,params,callback) {
	console.log(api_url)
	$.ajax({
		beforeSend: function(){
		},
		complete: function(){
		},
		type: "GET",
		contentType: "application/json",
		url: api_url,
		dataType: "json",
		data: params,
		success: callback,
		error: function(data){
			console.log(data)
			console.log("error")
		}
	})
}