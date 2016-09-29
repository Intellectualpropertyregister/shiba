class ScheduledJobsController < ApplicationController
  before_action :set_scheduled_job, only: [:show, :edit, :update, :destroy]
  respond_to :html, :json

	def index
		@scheduled_jobs = ScheduledJob.all
	end

	def new
		@scheduled_job = ScheduledJob.new
	end

	def show
		respond_with(@scheduled_job)
  end

  def create
    @scheduled_job = ScheduledJob.new(scheduled_job_params)
    ap params[:scheduled_job][:worker_name]
    respond_to do |format|
      if @scheduled_job.save
        # KibaWorker.perform_async(@scheduled_job.id)
        input = Hash.new
        Sidekiq::Cron::Job.create(name: @scheduled_job.description, cron: @scheduled_job.cron_schedule, class: params[:scheduled_job][:worker_name], args:@scheduled_job.city_id)
        format.html { redirect_to @scheduled_job, notice: 'Worker was successfully created.' }
        format.json { render :show, status: :created, location: @scheduled_job }
      else
        format.html { render :new }
        format.json { render json: @scheduled_job.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @scheduled_job.destroy
    respond_to do |format|
      format.html { redirect_to scheduled_jobs_url, notice: 'Worker was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def set_scheduled_job
      @scheduled_job = ScheduledJob.find(params[:id])
    end

    def scheduled_job_params
      params.require(:scheduled_job).permit(:description, :cron_schedule, :job_command, :city_id)
    end
end