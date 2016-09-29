class CitiesCrimeTypeWeightsController < ApplicationController

	before_action :set_city_crime_type_weight, only: [:show,:edit,:update,:destroy]
	before_filter :set_exponential_value, only: [:create, :update]
	def index 
		@q = CitiesCrimeTypeWeight.joins(:crime_type).ransack(params[:q])
		if params[:format] == 'json'
			@city_crime_type_weights = @q.result.order("crime_types.name asc")
		else
			@city_crime_type_weights = @q.result.order("crime_types.name asc").page(params[:page]).per(25)
		end
		respond_to do |format|
	      format.html
	      format.json { render :json => @city_crime_type_weights }
	    end
	end

	def show
	end

	def edit
	end


	def update
		respond_to do |format|
	      if @city_crime_type_weight.update(city_crime_weight_params)
	      	update_crime_data()
	        format.html { redirect_to cities_crime_type_weights_path, notice: 'City-Crime Type Weight was successfully updated.' }
	        format.json { render :show, status: :ok, location: @city_crime_type_weight }
	      else
	        format.html { render :edit }
	        format.json { render json: @city_crime_type_weight.errors, status: :unprocessable_entity }
	      end
	    end
	end
	
	def update_table
		@city_crime_type_weights = CitiesCrimeTypeWeight.all
		# ap @city_crime_type_weights
		@cities = City.all
		@crime_types = CrimeType.all
		@cities.each do |city|
			@crime_types.each do |crime_type|
				@new_city_crime_type_weight = CitiesCrimeTypeWeight.create!(city_id: city.id,crime_type_id: crime_type.id,crime_weight: crime_type.crime_weight) if @city_crime_type_weights.where(city_id: city.id, crime_type_id: crime_type.id).blank?
			end
		end
		redirect_to cities_crime_type_weights_path
	end

	private 

	def set_city_crime_type_weight
		@city_crime_type_weight = CitiesCrimeTypeWeight.find(params[:id])
		@city_crime_type_weight.crime_scale = calculate_logarithm_value(@city_crime_type_weight.crime_weight)
	end

	def city_crime_weight_params
		params.require(:cities_crime_type_weight).permit(:crime_weight)
	end

	def set_exponential_value

      @city_crime_type_weight.crime_weight = (2**(0.75 * params[:cities_crime_type_weight][:crime_scale].to_f)).round(1)
    end

    def calculate_logarithm_value crime_weight
      return 1 unless crime_weight > 0.0
      harmful_level = (Math.log2(crime_weight) )/ 0.75
      if harmful_level - harmful_level.floor > 0.5
        return harmful_level.ceil
      else 
        return harmful_level.floor
      end
    end

    def update_crime_data
    	@all_crime_data = CrimeData.where(city_id: @city_crime_type_weight.city_id, crime_type_id: @city_crime_type_weight.crime_type_id)
    	return unless @all_crime_data
    	@all_crime_data.each do |crime|
    		crime.update(crime_weight: @city_crime_type_weight.crime_weight)
    	end
    end
end
