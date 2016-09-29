namespace :dataplatform do
  desc 'Run a worker to do some data job from RabbitMQ'
  task worker: :environment do
    connection = Bunny.new(host: APP_CONFIG["rabbitmq_host"], port: APP_CONFIG["rabbitmq_port"])
    connection.start

    channel =  connection.create_channel
    channel.prefetch(1)
    queue = channel.queue(APP_CONFIG["rabbitmq_queue_name"])

    sns = Aws::SNS::Client.new(region: "us-east-1")
		sns_topic_arn = "arn:aws:sns:us-east-1:971758272077:dataplatform-workers"

    Rails.logger.info "Listening on #{APP_CONFIG['rabbitmq_host']}:#{APP_CONFIG['rabbitmq_port']}/#{APP_CONFIG['rabbitmq_queue_name']}..."
    queue.subscribe(block: true, manual_ack: true) do |delivery_info, metadata, payload|
    	Rails.logger.info "Received #{payload}"

    	begin
    		payload_array = payload.split("_")
    		source = payload_array[0]
    		city = payload_array[1]
    		result = payload_array[2]

    		if result == "delta"
    			DeltaWorker.new.perform(city)
    			# CalculateDeltaWorker.new.perform(city)
    		elsif result == "spike"
    			SpikeWorker.new.perform(city)
    		elsif result == "correlation"
    			AssociateCrimeWorker.new.perform(city)
    		elsif result == "visualise"
    			CrimeVisualiseWorker.new.perform(city)
    		elsif result == "citymatrix"
    			CityCrimeMatrix.new.perform(city, false)
    		elsif result == "historycitymatrix"
    			CityCrimeMatrix.new.perform(city, true)
    		elsif result == "done"
    			if source == "delta"
    				SpikeDetectWorker.new.perform(city)
    			elsif source == "spike"

    			end
    		elsif result == "postgisgrid"
    			PostgisGridWorker.new.perform(city)
    		elsif result == "routerating"
  				RouteRatingWorker.new.perform(city)
    		elsif result == "reportworker"
    			ReportWorker.new.perform(city)
    		end

  			channel.ack(delivery_info.delivery_tag, false)
        sns.publish({
          topic_arn: sns_topic_arn,
          message: "Task with payload #{payload} has just been finished.",
          subject: "[DATAPLATFORM] Finished Task #{payload}"
        }) if Rails.env.production?
    	rescue => e
    		Rails.logger.error "Something error while processing #{payload}"
    		Rails.logger.error "#{e}"
    		Rails.logger.error "#{e.backtrace.join("\n\t")}"
    		channel.nack(delivery_info.delivery_tag, false, false)
        sns.publish({
          topic_arn: sns_topic_arn,
          message: "Task with payload #{payload} was error: <code>#{e}</code><pre>#{e.backtrace.join("\n\t")}</pre>",
          subject: "[DATAPLATFORM] Task Error #{payload}"
        }) if Rails.env.production?
    	end
    end
  end

  task watcher: :environment do
    if Rails.env.production?
      `echo "#{Process.pid}" > #{Rails.root}/log/dataplatform_watcher.pid`
      
      connection = Bunny.new(host: APP_CONFIG['rabbitmq_host'], port: APP_CONFIG['rabbitmq_port'])
      connection.start

      channel =  connection.create_channel
      channel.prefetch(1)
      queue = channel.queue(APP_CONFIG['rabbitmq_queue_name'])

      autoscaling_group_name = 'dataplatform-worker-asg'
      autoscaling = Aws::AutoScaling::Client.new(region: 'us-east-1')

      sns = Aws::SNS::Client.new(region: 'us-east-1')
  		sns_topic_arn = 'arn:aws:sns:us-east-1:971758272077:dataplatform-workers'

      Rails.logger.info "Watching on #{APP_CONFIG['rabbitmq_host']}:#{APP_CONFIG['rabbitmq_port']}/#{APP_CONFIG['rabbitmq_queue_name']}..."

      queue.subscribe(block: true, manual_ack: true) do |delivery_info, metadata, payload|
        Rails.logger.info "Received #{payload}"

        begin
          resp = autoscaling.describe_auto_scaling_groups({
            auto_scaling_group_names: [autoscaling_group_name],
            max_records: 1
          })
          if resp.auto_scaling_groups[0].instances.size == 0 then
            Rails.logger.info "No workers are found. Spin up a new instance."
			      sns.publish({
			        topic_arn: sns_topic_arn,
			        message: "No workers are found to run #{payload}. Spin up a new instance.",
			        subject: "[DATAPLATFORM] Spin up a new worker #{payload}"
			      })
						autoscaling.set_desired_capacity({
						  auto_scaling_group_name: autoscaling_group_name,
						  desired_capacity: 1
						})
          else
            Rails.logger.info "Found #{resp.auto_scaling_groups[0].instances.size} worker instance(s)."
					end
        rescue => e
          Rails.logger.error "Something error while processing #{payload}"
          Rails.logger.error "#{e}"
          Rails.logger.error "#{e.backtrace.join("\n\t")}"
          sns.publish({
            topic_arn: sns_topic_arn,
            message: "Watching task with payload #{payload} was error: <code>#{e}</code><pre>#{e.backtrace.join("\n\t")}</pre>",
            subject: "[DATAPLATFORM] Task Error #{payload}"
          })
        end

        sleep(2.minutes)
        Rails.logger.info "Re-releasing job #{payload}."
        channel.nack(delivery_info.delivery_tag, false, true)
      end
    else
      Rails.logger.warn "Could not watch queue jobs on #{Rails.env}"
    end
  end
end
