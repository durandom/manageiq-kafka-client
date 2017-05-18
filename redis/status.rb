require 'redis'

redis_password = `oc get secret redis -o jsonpath={.data.database-password} | base64 --decode`
redis_host = `minishift ip`.chomp
redis_port = `oc get svc redis-ingress -o jsonpath={.spec.ports..nodePort}`

redis = Redis.new(:password => redis_password, :host => redis_host, :port => redis_port)

s = {
    :pods => {},
    :logs_collector => {},
    :logs_inventory => {},
    :collectors => {}
}

def heading(s)
  puts "\n"
  puts s
  puts '-' * s.length
end

redis.keys("*").each do |key|
  if key =~ /^manageiq-inventory/
    s[:pods][key] = redis.get key
  elsif key =~ /^log_manageiq-inventory/
    key =~ /log_(manageiq-inventory-[^_]*)_(\d+)/
    s[:logs_inventory][$1] ||= {}
    s[:logs_inventory][$1][$2] = redis.lrange key, -10, -1
  elsif key =~ /^log_/
    s[:logs_collector][key] = redis.lrange key, -10, -1
  elsif key =~ /^\d+$/
    s[:collectors][key] = redis.get key
  end
end

heading "Job Counters Inventory - # of events processed"
s[:pods].each do |pod, counter|
  puts "#{pod}: #{counter}"
end

heading "Job Counters Collector - # of events processed per Collector"
s[:collectors].sort.each do |collector, counter|
  puts "Collector ID #{collector}: #{counter}"
end

heading "Job tail per Collector - processed events"
s[:logs_collector].sort.each do |k, v|
  k =~ /log_(\d+)/
  puts "#{$1}: #{v.join ' '}"
end

heading "Job tail per Collector_Inventory - processed events"
s[:logs_inventory].sort.each do |k, v|
  puts k
  v.each do |collector, jobs|
    puts "  #{collector}: #{jobs.join ' '}"
  end
end
