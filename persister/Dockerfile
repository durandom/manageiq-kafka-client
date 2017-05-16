FROM durandom/container-ruby:latest
MAINTAINER hild@b4mad.net

RUN adduser app

RUN echo "RUBY_GEMS_ROOT=/opt/rubies/raby-2.3.1/lib/ruby/gems/2.3.0" >> /home/app/.bashrc && \
    echo 'PATH=$PATH:/opt/rubies/ruby-2.3.1/bin:/home/app/.gem/ruby/2.3.0/bin' >> /home/app/.bashrc && \
    echo 'export PATH' >> /home/app/.bashrc

COPY app/ /home/app/app
COPY docker-assets/container-entrypoint /home/app/container-entrypoint

RUN chown -R app /home/app/app && chmod 755 /home/app

USER app
WORKDIR /home/app/app
RUN source ~/.bashrc && \
    gem install --user-install bundler && \
    bundle install --path .bundle

ENTRYPOINT ["/home/app/container-entrypoint"]
CMD bundle exec ./persister.rb
