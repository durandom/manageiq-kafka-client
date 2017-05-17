require 'kafka'
require 'json'

ems = ENV['EMS'] || rand(1000)
kafka_broker = ENV['KAFKA_BROKER'] || 'apache-kafka:9092'

logger = Logger.new(STDOUT)
kafka = Kafka.new(
  seed_brokers: [ kafka_broker ],
  # logger: logger,
)


producer = kafka.producer

counter = 0
while true do
  counter += 1
  msg = {ems: ems, counter: counter}
  msg = JSON.generate(msg)
  producer.produce(msg, topic: "inventory")
  producer.deliver_messages
  puts "#{Time.now}: (ems: #{ems}) #{counter}"
  STDOUT.flush
  sleep 1
end
