desc 'Switch Rails logger log level to debug and use STDOUT'
task debug: :environment do
  Rails.logger = Logger.new(STDOUT)
  Rails.logger.level = Logger::DEBUG
end
