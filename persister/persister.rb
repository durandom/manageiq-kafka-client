require 'kafka'

logger = Logger.new(STDOUT)

kafka = Kafka.new(
    seed_brokers: ["apache-kafka:9092"],
    # logger: logger,
    client_id: "miq-persister",
)


consumer = kafka.consumer(group_id: "miq-persisters")
consumer.subscribe("inventory")
consumer.each_message do |message|
  p message
end
