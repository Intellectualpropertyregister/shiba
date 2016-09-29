
$redis = Redis.new(:host => APP_CONFIG['redis_host_name'], :port => APP_CONFIG['redis_port_number'],:db => 0)
# ap $redis