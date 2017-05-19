FROM manageiq/manageiq-pods:app-latest
MAINTAINER hild@b4mad.net

RUN curl -L https://github.com/durandom/manageiq/tarball/kafka | tar xz -C ${APP_ROOT} --strip 1
RUN echo "gem 'ruby-kafka'" >> Gemfile && echo "gem 'redis'" >> Gemfile && bundle update
RUN rm -rf log/* && chmod 777 log tmp tmp/cache . && chmod 666 tmp/cache/* Gemfile.lock
COPY database.yml config/database.yml
COPY database_configuration.rb config/environments/patches/database_configuration.rb

CMD [ "/bin/sh" ]

