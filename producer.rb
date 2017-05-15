require "kafka"
logger = Logger.new(STDOUT)
kafka = Kafka.new(
  # At least one of these nodes must be available:
  seed_brokers: ["localhost:9092"],
  logger: logger,
  # Set an optional client id in order to identify the client to Kafka:
  # client_id: "my-application",
)

# `#async_producer` will create a new asynchronous producer.
producer = kafka.async_producer

# The `#produce` API works as normal.
producer.produce("hello", topic: "greetings")

# `#deliver_messages` will return immediately.
producer.deliver_messages

# Make sure to call `#shutdown` on the producer in order to avoid leaking
# resources. `#shutdown` will wait for any pending messages to be delivered
# before returning.
producer.shutdown

# producer = kafka.producer
# Add a message to the producer buffer.
# producer.produce("hello1", topic: "test-messages")

# Deliver the messages to Kafka.
# producer.deliver_messages

# kafka.each_message(topic: "funky") do |message|
#   puts message.offset, message.key, message.value
# end
# kafka.deliver_message("Hello, World!", topic: "funky")

