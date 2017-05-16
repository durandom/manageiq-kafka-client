require "kafka"
logger = Logger.new(STDOUT)
kafka = Kafka.new(
  seed_brokers: ["localhost:9092"],
  logger: logger,
)


def produce_async(kafka)
  producer = kafka.async_producer
  producer.deliver_messages

  # The consumer can be stopped from the command line by executing
  # `kill -s QUIT <process-id>`.
  trap("QUIT") { producer.shutdown }

  while true
    msg = Time.now.to_f.to_s
    producer.produce(msg, topic: "inventory")
    puts msg
    sleep 1
  end
end

def produce_sync(kafka)
  producer = kafka.producer

  trap("QUIT") { exit }

  while true do
    msg = Time.now.to_f.to_s
    producer.produce(msg, topic: "inventory")
    producer.deliver_messages
    puts msg
    # sleep 1
  end

end

produce_sync(kafka)
