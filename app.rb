require 'sinatra'
require 'kafka'


get '/produce' do
  kafka = Kafka.new(
      # At least one of these nodes must be available:
      seed_brokers: ["apache-kafka:9092"],
      logger: logger,
  )
  producer = kafka.async_producer
  producer.produce("bla", topic: "greetings")
  producer.deliver_messages
  producer.shutdown
  "produced"
end

get '/consume' do
  kafka = Kafka.new(
      # At least one of these nodes must be available:
      seed_brokers: ["apache-kafka:9092"],
      logger: logger,
  )

  # consumer = kafka.consumer(group_id: "my-consumer")
  # consumer.subscribe("greetings")


  # stream do |out|
    # consumer.each_message do |message|
    #   out << "#{message.topic}, #{message.partition}, #{message.offset}, #{message.key}, #{message.value}"
    # end
  # end

  stream do |out|
    kafka.each_message(topic: "greetings") do |message|
      out << "#{message.topic}, #{message.partition}, #{message.offset}, #{message.key}, #{message.value}"
    end
  end

end
