require 'json'
class DashboardController < ApplicationController
	

	before_action only:[:show, :edit, :update, :destroy]
	respond_to :json

	CITY_GRID_CRIME = APP_CONFIG['city_crime_grid']
	CITY_GRID_FEATURES = APP_CONFIG['city_grid_feature']
	
	def index
		@q = CrimeData.ransack(params[:q])
		if params[:format] == "json"
	      @crimes = @q.result.order("updated_at desc")
	    else
	      @crimes = @q.result.order("id desc").page(params[:page]).per(50)
	    end
	    respond_to do |format|
	    	format.html 
	      format.json { render :json => @crimes }
	    end
	end

	
end
