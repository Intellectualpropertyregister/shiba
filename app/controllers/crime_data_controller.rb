# CrimeDataController
# -------------
# This class handles all the methods relating to accepting, processing and sending off crime data.

class CrimeDataController < ApplicationController
  before_action :set_crime_data, only: [:show, :edit, :update, :destroy]
  respond_to :json

  # GET /crime_data
  def index
    @q = CrimeData.ransack(params[:q])
    if params[:format] == "json"
      @crime_datas = @q.result.order("updated_at desc")
    else
      @crime_datas = @q.result.order("id desc").page(params[:page]).per(50)
    end

    respond_to do |format|
      format.html
      format.json { render :json => @crime_datas }
    end
  end
  
  # GET crime_data/id
  def show
    @crime_data = CrimeData.find(params[:id])
  end

  def edit
  end

  def update
    respond_to do |format|
      if @crime_data.update(crime_data_params)
        format.html { redirect_to @crime_data, notice: 'Crime data was successfully updated.' }
        format.json { render :show, status: :ok, location: @crime_data }
      else
        format.html { render :edit }
        format.json { render json: @crime_data.errors, status: :unprocessable_entity }
      end
    end
  end

  def reports
    
  end

  def crimes_by_day
    @crime_data = CrimeData.find_by_sql("SELECT date_trunc('day', crime_data.occurred_at) AS date, COUNT(crime_data.id) AS total_crime FROM crime_data WHERE crime_data.occurred_at >= '2015-01-01' AND crime_data.occurred_at <= '2015-03-31' GROUP BY date_trunc('day', crime_data.occurred_at) ORDER BY date ASC")
    @cdata = @crime_data.map { |o| 
      formatted_date = "Date.UTC(#{o.date.strftime('%Y')},#{o.date.strftime('%-m')},#{o.date.strftime('%e')})"
      [o.date, o.total_crime] 
    }
    # p @cdata
    respond_to do |format|
      format.json { render json: @cdata }
    end
  end

  def test 
   @crime_data = historical_by_week("THEFT",2005,10)
    respond_to do |format|
      format.html { render json: @crime_data }
      format.json { render json: @crime_data }
    end
  end

  def historical_by_week crime_type, year, month
    @cdata = CrimeData.where('crime_type = ? AND extract(year from crime_date) = ? 
      AND extract(month from crime_date) = ?',
      crime_type,
      year,
      month)
    

     @cdata

  end

  private 

  def crime_data_params
    params.require(:crime_data).permit(:primary_type)
  end

  private 

  def set_crime_data
    @crime_data = CrimeData.find(params[:id])
  end

end
