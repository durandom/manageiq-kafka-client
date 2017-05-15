require "kafka"
logger = Logger.new(STDOUT)
kafka = Kafka.new(
  # At least one of these nodes must be available:
  seed_brokers: ["localhost:9092"],
  logger: logger,
  # Set an optional client id in order to identify the client to Kafka:
  # client_id: "my-application",
)


consumer = kafka.consumer(group_id: "my-consumer")
consumer.subscribe("greetings")
consumer.each_message do |message|
  p message
end

# kafka.each_message(topic: "greetings") do |message|
#   puts message.offset, message.key, message.value
#   p message
# end

