FROM cruglobal/base-image-ruby-version-arg:2.3.0
MAINTAINER cru.org <wmd@cru.org>

COPY docker/webapp.conf /usr/local/openresty/nginx/conf.d/webapp.conf
