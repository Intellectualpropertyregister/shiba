class WorkersController < ApplicationController

  def index
    @sources = ["delta", "spike"]
    @cities = City.order(:name).all
    @results = ["citymatrix", "delta", "spike", "correlation", "visualise", "historycitymatrix", "done", "postgisgrid", "routerating", "reportworker"]
  end

  def create
    @payload = "#{params[:source]}_#{params[:city_id]}_#{params[:result]}"

    conn = Bunny.new(host: APP_CONFIG["rabbitmq_host"], port: APP_CONFIG["rabbitmq_port"])
    conn.start
    channel = conn.create_channel
    queue  = channel.queue(APP_CONFIG["rabbitmq_queue_name"])
    queue.publish(@payload)
    conn.stop
  end
end
