FROM 172.30.1.1:5000/myproject/manageiq-base:latest
MAINTAINER hild@b4mad.net

COPY inventory.rb inventory.rb

ENV RAILS_USE_MEMORY_STORE=1 RAILS_ENV=production
CMD rails runner inventory.rb
