class ScheduledJob < ActiveRecord::Base
	attr_accessor :worker_name
	belongs_to :city

	validates :city, presence: true
  	validates :cron_schedule, presence: true
  	validates :job_command, presence: true
  	validates :description, presence: true

end
