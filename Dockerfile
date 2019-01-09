FROM 056154071827.dkr.ecr.us-east-1.amazonaws.com/base-image-ruby-version-arg:2.3
MAINTAINER cru.org <wmd@cru.org>

ARG SIDEKIQ_CREDS

COPY Gemfile Gemfile.lock ./
COPY docker/pagespeed.conf /usr/local/openresty/nginx/conf/pagespeed.conf

RUN bundle config gems.contribsys.com $SIDEKIQ_CREDS
RUN bundle install --jobs 20 --retry 5 --path vendor
RUN bundle binstubs bundler --force
RUN bundle binstub puma sidekiq rake

COPY . ./

## Run this last to make sure permissions are all correct
RUN mkdir -p /home/app/webapp/tmp /home/app/webapp/db /home/app/webapp/log /home/app/webapp/public/uploads && \
  chmod -R ugo+rw /home/app/webapp/tmp /home/app/webapp/db /home/app/webapp/log /home/app/webapp/public/uploads