require 'kafka'
require 'redis'
require 'json'

logger = Logger.new(STDOUT)
redis_host = ENV['REDIS_SERVICE_HOST']
redis_port = ENV['REDIS_SERVICE_PORT']
redis_password = ENV['REDIS_PASSWORD']

sleep_max = ENV['SLEEP_MAX']
pod = ENV['HOSTNAME']

kafka = Kafka.new(
    seed_brokers: ["apache-kafka:9092"],
    # logger: logger,
    client_id: "miq-persister",
)

redis = Redis.new(:password => redis_password, :host => redis_host, :port => redis_port)

consumer = kafka.consumer(group_id: "miq-persisters")
consumer.subscribe("inventory")

consumer.each_message do |message|
  # begin
  #   msg = JSON.load(message.value)
  # rescue JSON::ParserError
  #   p "err parsing #{message.value}"
  #   next
  # end

  # ems = msg['ems']
  # counter = msg['counter']

  # redis.incr(pod)
  # redis.incr(ems)
  # redis.rpush("log_#{ems}", counter)
  # redis.rpush("log_#{pod}_#{ems}", counter)

  # puts "#{Time.now}: (ems: #{ems}) #{counter}"
  puts "Received inventory"
  persister = ManagerRefresh::Inventory::Persister.from_yaml(message.value)

  puts "Saving inventory"
  ManagerRefresh::SaveInventory.save_inventory(persister.manager, persister.inventory_collections)
  puts "Saving inventory...Complete"
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
