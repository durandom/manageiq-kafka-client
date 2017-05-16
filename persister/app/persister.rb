#!/bin/env ruby

require 'kafka'

logger = Logger.new(STDOUT)

kafka = Kafka.new(
    seed_brokers: ["apache-kafka:9092"],
    logger: logger,
    client_id: "miq-persister",
)

kafka.each_message(topic: "greetings") do |message|
  p "#{message.topic}, #{message.partition}, #{message.offset}, #{message.key}, #{message.value}"
end

# consumer = kafka.consumer(group_id: "my-consumer")
# consumer.subscribe("greetings")
# consumer.each_message do |message|
#   p message
# end
