class CrimeTypeDescriptionsController < ApplicationController
  before_action :set_crime_type_description, only: [:show, :edit, :update, :destroy]

  # GET /crime_type_descriptions
  # GET /crime_type_descriptions.json
  def index
    @crime_type_descriptions = CrimeTypeDescription.all.order("crime_type_id asc")
  end

  # GET /crime_type_descriptions/remark
  # GET /crime_type_descriptions/remark.json
  def remark
    @crime_type_descriptions = CrimeTypeDescription.where(crime_type_id: 80).order("crime_type_id asc")
  end

  # GET /crime_type_descriptions/1
  # GET /crime_type_descriptions/1.json
  def show
  end

  # GET /crime_type_descriptions/new
  def new
    @crime_type_description = CrimeTypeDescription.new
  end

  # GET /crime_type_descriptions/1/edit
  def edit
  end

  # POST /crime_type_descriptions
  # POST /crime_type_descriptions.json
  def create
    @crime_type_description = CrimeTypeDescription.new(crime_type_description_params)

    respond_to do |format|
      if @crime_type_description.save
        format.html { redirect_to @crime_type_description, notice: 'Crime type description was successfully created.' }
        format.json { render :show, status: :created, location: @crime_type_description }
      else
        format.html { render :new }
        format.json { render json: @crime_type_description.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /crime_type_descriptions/1
  # PATCH/PUT /crime_type_descriptions/1.json
  def update
    respond_to do |format|
      if @crime_type_description.update(crime_type_description_params)
        update_crime_data(@crime_type_description)
        format.html { redirect_to @crime_type_description, notice: 'Crime type description was successfully updated.' }
        format.json { render :show, status: :ok, location: @crime_type_description }
      else
        format.html { render :edit }
        format.json { render json: @crime_type_description.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /crime_type_descriptions/1
  # DELETE /crime_type_descriptions/1.json
  def destroy
    @crime_type_description.destroy
    respond_to do |format|
      format.html { redirect_to crime_type_descriptions_url, notice: 'Crime type description was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_crime_type_description
    @crime_type_description = CrimeTypeDescription.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def crime_type_description_params
    params.require(:crime_type_description).permit(:name, :description, :crime_type_id)
  end

  def update_crime_data crime_type_description
    @crime_data = CrimeData.where(crime_type_description_id: crime_type_description.id)
    crime_type = CrimeType.find(crime_type_description.crime_type_id)
    @crime_data.each do |crime|
      crime.update(crime_type_id: crime_type_description.crime_type_id, crime_weight: crime_type.crime_weight)
    end
  end
end
