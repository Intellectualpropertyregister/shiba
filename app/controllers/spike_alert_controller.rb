require 'dynamodb_service'
class SpikeAlertController < ApplicationController
	before_action only:[:show, :edit, :update, :destroy]
	respond_to :json

	DYNAMODB_TABLE = APP_CONFIG['dynamodb_ss']
	SPIKE_ALERT = APP_CONFIG['spike_report']

	def index

		city_name = "chicago"

		@alert_reports = Hash.new
		dynamodb = DynamodbService.new
		alert_list_key = SPIKE_ALERT + city_name
		alert_list_reponse = dynamodb.get_value(DYNAMODB_TABLE,alert_list_key)
		if(alert_list_reponse != nil)
			if(alert_list_reponse.item!= nil)
				alert_list = alert_list_reponse.item["#{alert_list_key}"]
				if(alert_list != nil)
					alert_list.each do |key,value|
						spike_report_reponse = dynamodb.get_value(DYNAMODB_TABLE,key)
						if(spike_report_reponse.item != nil)
							spike_report = spike_report_reponse.item["#{key}"]
							# ap spike_report
							crime_list = []
							spike_report.each do |k,v|
								crime_detail = Hash.new
								if(k != "created_at")
									crime_detail["crime_name"] = k
									crime_detail["count"] = v["count"].to_i
									crime_detail["spike"] = v["spike"]
									crime_detail["row_index"] = value["row_index"].to_i
									crime_detail["col_index"] = value["col_index"].to_i
									crime_list << crime_detail
								end # not equal to created_at
							end #spike_report Loop
							@alert_reports["#{key}"] = crime_list
						end # reponse item is nil
					end # alert_list Loop
				end # spike_list is nil
			end #alert_list_reponse item is nil
		end # alert_list_reponse is nil
		
		# ap @alert_reports
		respond_to do |format|
	    	format.html 
	      format.json { render :json => @alert_reports }
	    end
	end

	
end
