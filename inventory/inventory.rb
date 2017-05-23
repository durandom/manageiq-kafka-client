require 'kafka'
require 'redis'
require 'json'

logger = Logger.new(STDOUT, level: :info)
logger = Logger.new(nil)
redis_host = ENV['REDIS_SERVICE_HOST']
redis_port = ENV['REDIS_SERVICE_PORT']
redis_password = ENV['REDIS_PASSWORD']

sleep_max = ENV['SLEEP_MAX']
pod = ENV['HOSTNAME']

kafka = Kafka.new(
    seed_brokers: ["apache-kafka:9092"],
    logger: logger,
    client_id: "miq-persister",
)

redis = Redis.new(:password => redis_password, :host => redis_host, :port => redis_port)

consumer = kafka.consumer(
    group_id: "miq-persisters",
    session_timeout: 240,
)
consumer.subscribe("inventory", start_from_beginning: false)

counter = 0
consumer.each_message do |message|
  begin
    msg = JSON.load(message.value)
  rescue JSON::ParserError
    p "err parsing #{message.value}"
    next
  end

  counter += 1
  key = "#{msg['ems']}_#{msg['job']}"
  delay = Time.now.to_f - Float(msg['time'])
  puts "Received inventory #{key}, partition #{message.partition}, batch #{msg['batch']}, delay: #{delay}"
  begin
    persister = ManagerRefresh::Inventory::Persister.from_yaml(msg['data'])
  rescue => e
    pp e
    redis.set("err_#{key}", e.message)
  end

  puts "Saving inventory"
  start = Time.now.to_f
  begin
    ManagerRefresh::SaveInventory.save_inventory(persister.manager, persister.inventory_collections)
  rescue => e
    pp e
    redis.set("err_#{key}", e.message)
  end

  time = Time.now.to_f - start
  puts "Saving inventory...Complete - time: #{time}"


  redis.incr(pod)
  redis.incr(msg['ems'])
  redis.rpush("job_start_#{key}", start)
  redis.rpush("job_end_#{key}", Time.now.to_f)
  redis.rpush("job_done_#{key}", msg['time'])
  redis.rpush("job_done_batch_#{key}", msg['batch'])
  redis.rpush("job_save_time_#{key}" , time)
  # redis.rpush("log_#{pod}_#{msg['ems']}", counter)
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
