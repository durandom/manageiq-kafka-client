FROM 172.30.1.1:5000/myproject/manageiq-base:latest
MAINTAINER hild@b4mad.net

COPY collector.rb collector.rb
COPY validate.rb validate.rb

ENV RAILS_USE_MEMORY_STORE=1 RAILS_ENV=production
CMD rails runner collector.rb
