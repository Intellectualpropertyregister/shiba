class CrimeTypesController < ApplicationController
  before_action :set_crime_type, only: [:show, :edit, :update, :destroy, :list_descriptions]
  # before_filter :set_exponential_value, only: [:create, :update] -- moved into model

  def index
    @crime_types = CrimeType.all.order("name asc")
  end

  def list_descriptions
  end

  def show
  end

  def new
    @crime_type = CrimeType.new
  end

  def edit
  end

  def create
    @crime_type = CrimeType.new(crime_type_params)

    respond_to do |format|
      if @crime_type.save
        format.html { redirect_to @crime_type, notice: 'Crime Type was successfully created.' }
        format.json { render :show, status: :created, location: @crime_type }
      else
        format.html { render :new }
        format.json { render json: @crime_type.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @crime_type.update(crime_type_params)
        format.html { redirect_to crime_types_path, notice: 'Crime Type was successfully updated.' }
        format.json { render :show, status: :ok, location: @crime_type }
      else
        format.html { render :edit }
        format.json { render json: @crime_type.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @crime_type.destroy
    respond_to do |format|
      format.html { redirect_to crime_types_url, notice: 'Crime Type was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_crime_type
      @crime_type = CrimeType.find(params[:id])
      @crime_type.crime_scale = calculate_logarithm_value(@crime_type.crime_weight)
      # ap @crime_type
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def crime_type_params
      params.require(:crime_type).permit(:name, :display_name, :description, :subtype_of, :violent, :crime_scale)
    end

    # def set_exponential_value
    #   @crime_type.crime_weight = (2**(0.75 * params[:crime_type][:crime_scale].to_f)).round(1)
    # end

    def calculate_logarithm_value crime_weight
      return 0 unless crime_weight.to_f > 0.0
      harmful_level = (Math.log2(crime_weight) )/ 0.75
      if harmful_level - harmful_level.floor > 0.5
        return harmful_level.ceil
      else
        return harmful_level.floor
      end
    end
end
