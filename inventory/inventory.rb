require 'kafka'
require 'redis'
require 'json'

logger = Logger.new(STDOUT)
redis_host = ENV['REDIS_HOST'] || 'redis'
redis_port = ENV['REDIS_PORT'] || 6379
sleep_max = ENV['SLEEP_MAX']

kafka = Kafka.new(
    seed_brokers: ["apache-kafka:9092"],
    # logger: logger,
    client_id: "miq-persister",
)

# FIXME: make that configurable
redis = Redis.new(:password => "qik48IoStyJr8Rxi", :host => redis_host, :port => redis_port)

consumer = kafka.consumer(group_id: "miq-persisters")
consumer.subscribe("inventory")

consumer.each_message do |message|
  begin
    msg = JSON.load(message.value)
  rescue JSON::ParserError
    p "err parsing #{message.value}"
    next
  end

  ems = msg['ems']
  counter = msg['counter']

  # x = redis.incr(key)
  puts "#{Time.now}: (ems: #{ems}) #{counter}"
  STDOUT.flush

  # next unless sleep_max
  # sleep_time = rand sleep_max.to_i
  # p "sleep #{sleep_time}..."
  # sleep sleep_time
  # p "...wakeup"
  # STDOUT.flush
  # p "#{message.topic}, #{message.partition}, #{message.offset}, #{message.key}, #{message.value}"
  # p message
end
