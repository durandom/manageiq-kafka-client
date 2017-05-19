require 'redis'

redis_password = `oc get secret redis -o jsonpath={.data.database-password} | base64 --decode`
redis_host = `minishift ip`.chomp
redis_port = `oc get svc redis-ingress -o jsonpath={.spec.ports..nodePort}`

redis = Redis.new(:password => redis_password, :host => redis_host, :port => redis_port)

def heading(s)
  puts "\n"
  puts s
  puts '-' * s.length
end

s = Hash.new {|h, k| h[k] = Hash.new{|x,y| x[y] = {} } }

# 1) "job_save_time_aws1_2"
# 2) "job_done_batch_aws1_1"
# 3) "job_done_aws1_2"
# 4) "job_done_aws1_1"
# 5) "log_manageiq-inventory-1-6mfw8_aws1"
# 6) "job_aws1_2"
# 7) "job_done_batch_aws1_2"
# 8) "job_aws1_1"
# 9) "job_save_time_aws1_1"
# 10) "manageiq-inventory-1-6mfw8"
# 11) "aws1"

redis.keys("*").each do |key|
  case key
    when /^job_save_time/
      key =~ /job_save_time_([^_]*)_(\d+)/
      s[:job_save_time][$1][$2] = redis.lrange key, 0, -1
    when /^job_done_batch_/
      key =~ /job_done_batch_([^_]*)_(\d+)/
      s[:job_done_batch][$1][$2] = redis.lrange key, 0, -1
    when /^job_done_/
      # this array grows upon completion, useful for monitoring
      key =~ /job_done_([^_]*)_(\d+)/
      s[:job_done][$1][$2] = redis.lrange key, 0, -1
    when /^job_/
      key =~ /job_([^_]*)_(\d+)/
      s[:jobs][$1][$2] = redis.lrange key, 0, -1
    when /^manageiq-inventory/
      s[:pods][key] = redis.get key
    when /^log_manageiq-inventory/
      key =~ /log_(manageiq-inventory-[^_]*)_(\d+)/
      s[:logs_inventory][$1] ||= {}
      s[:logs_inventory][$1][$2] = redis.lrange key, -10, -1
  end
end

heading "Job Counters Inventory - # of jobs processed"
s[:pods].each do |pod, counter|
  puts "#{pod}: #{counter}"
end


heading "Jobs saving Time"
s[:job_save_time].sort.each do |k, v|
  puts "Collector #{k}"
  v.sort.each do |x, y|
    puts " job #{x}: #{y.map(&:to_f).sum.to_i} seconds"
  end
end

heading "Jobs done in batches"
s[:job_done_batch].sort.each do |k, v|
  puts "Collector #{k}"
  v.sort.each do |x, y|
    puts " job #{x}: #{y.join ' '}"
  end
end

exit

heading "Job tail per Collector_Inventory - processed events"
s[:logs_inventory].sort.each do |k, v|
  puts k
  v.each do |collector, jobs|
    puts "  #{collector}: #{jobs.join ' '}"
  end
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

