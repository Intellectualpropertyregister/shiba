require 'geo_formula'
require 'redis_service'
class PoisController < ApplicationController
  before_action :set_poi, only: [:show, :edit, :update, :destroy]
  before_filter :get_city_list, only: [:new, :edit]
  before_filter :get_coordinate_and_city, only: [:show, :edit]
  # GET /pois
  # GET /pois.json
  def index
    @pois = Poi.all
    @q = Poi.ransack(params[:q])
    if params[:format] == 'json'
        @pois = @q.result.order("name asc")
    else
        @pois = @q.result.order("name asc").page(params[:page]).per(25)
    end
    respond_to do |format|
      format.html
      format.json { render :json => @pois }
    end
  end

  # GET /pois/1
  # GET /pois/1.json
  def show
  end

  # GET /pois/new
  def new
    @poi = Poi.new
  end

  # GET /pois/1/edit
  def edit
  end

  # POST /pois
  # POST /pois.json
  def create
    @poi = Poi.new(poi_params)
    respond_to do |format|
      if @poi.save
          generate_zone(params[:poi][:latitude], params[:poi][:longitude],params[:poi][:city_id])
        format.html { redirect_to pois_path, notice: 'Poi was successfully created.' }
        format.json { render :show, status: :created, location: @poi }
      else
        format.html { render :new }
        format.json { render json: @poi.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pois/1
  # PATCH/PUT /pois/1.json
  def update
    respond_to do |format|
      if @poi.update(poi_params)
          update_zone(params[:poi][:latitude],params[:poi][:longitude],params[:poi][:city_id])
        format.html { redirect_to @poi, notice: 'Poi was successfully updated.' }
        format.json { render :show, status: :ok, location: @poi }
      else
        format.html { render :edit }
        format.json { render json: @poi.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pois/1
  # DELETE /pois/1.json
  def destroy
    @poi.destroy
    respond_to do |format|
      format.html { redirect_to pois_url, notice: 'Poi was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    def get_coordinate_and_city
        @poi.longitude = @poi[:location].x
        @poi.latitude = @poi[:location].y
        @poi.city_name = City.find(@poi[:city_id]).name
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_poi
        @poi = Poi.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def poi_params
        params[:poi][:city_id] = City.where(name: params[:poi][:city_name]).first.id
        if params[:poi][:latitude].length > 0 && params[:poi][:longitude].length > 0
            params[:poi][:location] = "POINT(#{params[:poi][:longitude]} #{params[:poi][:latitude]})"
        else
            if params[:poi][:address].length > 0
                geocode_address(params[:poi][:address], params[:poi][:city_name])
            else
                geocode_address(params[:poi][:name], params[:poi][:city_name])
            end
        end
      params.require(:poi).permit(:name, :address, :latitude, :longitude, :poi_safety_level, :city_name, :city_id,:location)
    end

    def get_city_list
        @city_name_list = City.all.select(:name).map{|i| i.name}
    end

    def update_zone lat,lng,city_id
        grid_report = get_gridreport(lat, lng, city_id)
        return unless grid_report
        polygon_coordinates = get_gridcoordinate(grid_report['crimeCoordinate'])
        @poi_zone = @poi.zone.update(name: @poi[:name],
        area: polygon_coordinates,
        zone_type: @poi[:poi_safety_level],
        city_id: @poi[:city_id],
        dark: true,
        daytime: true) if polygon_coordinates && @poi
    end


    def generate_zone lat,lng, city_id
        grid_report = get_gridreport(lat, lng, city_id)
        return unless grid_report
        polygon_coordinates = get_gridcoordinate(grid_report['crimeCoordinate'])
        if polygon_coordinates && @poi
            @poi_zone = Zone.create(name: @poi[:name],
            area: polygon_coordinates,
            zone_type: @poi[:poi_safety_level],
            city_id: @poi[:city_id],
            dark: true,
            daytime: true)
            @poi.zone = @poi_zone
        end
    end

    def get_gridreport lat,lng,city_id
        redis = RedisService.new
        @city = City.find(city_id)
        city_name = @city.name.downcase.gsub(" ","_")
        city_feature = redis.get_value(APP_CONFIG['city_grid_feature'].to_s + city_name)
        grid_index = get_row_col_index(lat,lng,@city[:south_west].y,@city[:south_west].x,city_feature['rowDimension'],city_feature['distanceBetweenCells'])
        row_index = grid_index[:row]
        col_index = grid_index[:col]
        if row_index < city_feature['rowDimension'] && col_index < city_feature['colDimension'] && row_index >= 0 && col_index >= 0
            grid_key = APP_CONFIG['city_crime_grid'].to_s + city_name + "_" + row_index.to_s + "_" + col_index.to_s
            return redis.get_value(grid_key)
        else
            return nil
        end
    end

    def get_gridcoordinate crime_coordinate
        return "POLYGON((#{crime_coordinate['topLeftLongitude']} #{crime_coordinate['topLeftLatitude']},
                    #{crime_coordinate['btmRightLongitude']} #{crime_coordinate['topLeftLatitude']},
                    #{crime_coordinate['btmRightLongitude']} #{crime_coordinate['btmRightLatitude']},
                    #{crime_coordinate['topLeftLongitude']} #{crime_coordinate['btmRightLatitude']},
                    #{crime_coordinate['topLeftLongitude']} #{crime_coordinate['topLeftLatitude']}))"
    end

    def get_row_col_index lat1,lng1,lat2,lng2,row_dimension,distance_btw_grid
		geo = GeoFormula.new
		grid_index = Hash.new
		grid_index[:row] = geo.to_row(row_dimension,lat2 ,lng1,lat1, lng1, distance_btw_grid)
		grid_index[:col] = geo.to_col(lat1, lng1, lat1, lng2,distance_btw_grid)
		grid_index
	end

    def geocode_address keyword , city_name
        response = Geocoder.search("#{keyword} #{city_name}").first
  		return unless response
  		location = response.geometry["location"]
        params[:poi][:location] = "POINT(#{location["lng"]} #{location["lat"]})"
  		params[:poi][:latitude] = location["lat"]
        params[:poi][:longitude] = location["lng"]
    end
end
