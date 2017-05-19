require 'kafka'
require 'json'
require 'redis'

redis_host = ENV['REDIS_SERVICE_HOST']
redis_port = ENV['REDIS_SERVICE_PORT']
redis_password = ENV['REDIS_PASSWORD']
$redis = Redis.new(:password => redis_password, :host => redis_host, :port => redis_port)

kafka_broker = ENV['KAFKA_BROKER'] || 'apache-kafka:9092'
$producer = Kafka.new(seed_brokers: [kafka_broker]).producer(compression_codec: :gzip)

def send_or_update(ems, persister, count, batch_size)
  if count == :rest || count > batch_size
    inventory_yaml = persister.to_yaml

    $batch_counter += 1
    puts "sending inventory batch #{$batch_counter} to kafka, #{inventory_yaml.size} bytes"
    msg = {
        job: $counter,
        batch: $batch_counter,
        ems: $ems,
        time: Time.now.to_f,
        data: inventory_yaml
    }

    payload = JSON.generate(msg)
    $producer.produce(payload, topic: 'inventory')
    $producer.deliver_messages

    key = "job_#{$ems}_#{$counter}"
    $redis.rpush key, msg[:time]

    # And and create new persistor so the old one with data can be GCed
    return_persister = ManageIQ::Providers::Amazon::Inventory::Persister::StreamedData.new(
      ems, ems
    )
    return_count     = 1
  else
    return_persister = persister
    return_count     = count + 1
  end

  return return_persister, return_count
end

def process_entity(ems, entity_name, starting_persister, starting_count, total_elements, batch_size)
  persister = starting_persister
  count     = starting_count

  (1..total_elements).each do |index|
    send("parse_#{entity_name.to_s}", index, persister)
    persister, count = send_or_update(ems, persister, count, batch_size)
  end

  return persister, count
end

def parse_orchestration_stack(index, persister)
  parent = index > 2 ? persister.orchestration_stacks.lazy_find("stack_#{index - 1}") : nil

  persister.orchestration_stacks.build(
    :ems_ref       => "stack_#{index}",
    :name          => "stack_#{index}_name",
    :description   => "stack_#{index}_description",
    :status        => "stack_#{index}_ok",
    :status_reason => "stack_#{index}_status_reason",
    :parent        => parent
  )
end

def parse_vm(index, persister)
  persister.vms.build(
    :ems_ref             => "instance_#{index}",
    :uid_ems             => "instance_#{index}_uid_ems",
    :name                => "instance_#{index}_name",
    :vendor              => "amazon",
    :raw_power_state     => "instance_#{index} status",
    :boot_time           => Time.now.utc, # this will cause that dta are updated in second + refresh
    :availability_zone   => persister.availability_zones.lazy_find("az_#{index}"),
    :flavor              => persister.flavors.lazy_find("flavor_#{index}"),
    :genealogy_parent    => persister.miq_templates.lazy_find("image_#{index}"),
    # :key_pairs           => [persister.key_pairs.lazy_find("key_pair_#{index}")],
    :location            => persister.networks.lazy_find("image_#{index}__public", :key => :hostname, :default => 'unknown'),
    :orchestration_stack => persister.orchestration_stacks.lazy_find("stack_#{index}")
  )
end

def parse_image(index, persister)
  persister.miq_templates.build(
    :ems_ref            => "image_#{index}",
    :uid_ems            => "image_#{index}_uid_ems",
    :name               => "image_#{index}_name",
    :location           => "image_#{index}_location",
    :vendor             => "amazon",
    :raw_power_state    => "never",
    :template           => true,
    :publicly_available => true
  )
end

def parse_flavor(index, persister)
  persister.flavors.build(
    :ems_ref                  => "flavor_#{index}",
    :name                     => "flavor_#{index}_name",
    :description              => "flavor_#{index}_description",
    :enabled                  => true,
    :cpus                     => 1,
    :cpu_cores                => 1,
    :memory                   => 1024,
    :supports_32_bit          => true,
    :supports_64_bit          => true,
    :supports_hvm             => true,
    :supports_paravirtual     => false,
    :block_storage_based_only => true,
    :cloud_subnet_required    => true,
    :ephemeral_disk_size      => 10,
    :ephemeral_disk_count     => 1
  )
end

def parse_availability_zone(index, persister)
  persister.availability_zones.build(
    :ems_ref => "az_#{index}",
    :name    => "az_#{index}_name"
  )
end

def parse_hardware(index, persister)
  persister.hardwares.build(
    :vm_or_template       => persister.vms.lazy_find("instance_#{index}"),
    :bitness              => 64,
    :virtualization_type  => "hvm",
    :root_device_type     => "root_device_type",
    :cpu_sockets          => 4,
    :cpu_cores_per_socket => 1,
    :cpu_total_cores      => 6,
    :memory_mb            => 600,
    :disk_capacity        => 200,
    :guest_os             => persister.hardwares.lazy_find("image_#{index}", :key => :guest_os),
  )
end

def parse_key_pair(index, persister)
  persister.key_pairs.build(
    :name        => "key_pair_#{index}",
    :fingerprint => "key_pair_#{index}_fingerprint"
  )
end

def generate_batches_od_data(ems_name:, total_elements:, batch_size: 1000)
  ems       = ExtManagementSystem.find_by(:name => ems_name)
  persister = ManageIQ::Providers::Amazon::Inventory::Persister::StreamedData.new(
    ems, ems
  )
  count     = 1

  persister, count = process_entity(ems, :vm, persister, count, total_elements, batch_size)
  persister, count = process_entity(ems, :image, persister, count, total_elements, batch_size)
  persister, count = process_entity(ems, :hardware, persister, count, total_elements, batch_size)
  persister, count = process_entity(ems, :availability_zone, persister, count, total_elements, batch_size)
  persister, count = process_entity(ems, :flavor, persister, count, total_elements, batch_size)
  persister, count = process_entity(ems, :orchestration_stack, persister, count, total_elements, batch_size)
  persister, count = process_entity(ems, :key_pair, persister, count, total_elements, batch_size)

  # Send or update the rest which is batch smaller than the batch size
  send_or_update(ems, persister, :rest, batch_size)
end


ems = ENV['EMS'] || rand(1000)
ExtManagementSystem.find_by(:name => ems) || ManageIQ::Providers::Amazon::CloudManager.create!(:name => ems, :hostname => 'localhost', provider_region: 'us-east-1', zone: Zone.first)
$counter = 0
$ems = ems
while true do
  $counter += 1
  $batch_counter = 0
  generate_batches_od_data(:ems_name => ems, :total_elements => 1234)
  # msg = {ems: ems, counter: counter}
  # msg = JSON.generate(msg)
  # producer.produce(msg, topic: "inventory")
  # producer.deliver_messages
  puts "#{Time.now}: (ems: #{ems}) #{$counter}"
  STDOUT.flush
  if $counter == 2
    puts "done - sleep for 1 day"
    sleep 24.hours
  else
    sleep 120
  end
end
