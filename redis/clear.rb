require 'redis'

redis_password = `oc get secret redis -o jsonpath={.data.database-password} | base64 --decode`
redis_host = `minishift ip`.chomp
redis_port = `oc get svc redis-ingress -o jsonpath={.spec.ports..nodePort}`

redis = Redis.new(:password => redis_password, :host => redis_host, :port => redis_port)
p redis.flushall

