FROM ubuntu:14.04
MAINTAINER Marcin Kulik

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update

# install required packages
RUN apt-get -y install git build-essential libmysqlclient-dev libxml2-dev \
  libxslt1-dev libreadline6 libicu-dev imagemagick nodejs sudo mysql-client \
  nginx cmake pkg-config sphinxsearch

# install Ruby 2.0 and make it a default Ruby
RUN apt-get install -y ruby2.0 ruby2.0-dev
RUN rm /usr/bin/ruby /usr/bin/gem /usr/bin/irb /usr/bin/erb && \
  ln -s /usr/bin/ruby2.0 /usr/bin/ruby && \
  ln -s /usr/bin/gem2.0 /usr/bin/gem && \
  ln -s /usr/bin/irb2.0 /usr/bin/irb && \
  ln -s /usr/bin/erb2.0 /usr/bin/erb && \
  gem update --system && gem pristine --all

# install bundler
RUN gem install bundler --no-rdoc --no-ri

# create directory for app files
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# add Gemfile first and run `bundle install` system-wide so bundle result can be cached
ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/
RUN bundle install --system --without postgres --jobs 4

# now add the rest of the app to the image
ADD . /usr/src/app

# make sure all Rails processes run in production env by default
ENV RAILS_ENV production

# build assets
RUN bundle exec rake assets:precompile
RUN git submodule update --recursive --init

# put revision (git sha) and version (tag + sha) into public/
RUN git rev-parse HEAD >public/REVISION && git describe --tags HEAD >public/VERSION

# add git user (with uid matching the uid of git user on the host)
RUN useradd -m -d /home/git -u 5000 -U git

# own app files to git so it can write to config, log and tmp when container is run as git
RUN chown -R git:git /usr/src/app

RUN ln -sf /usr/src/app/config/docker/nginx/nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000
EXPOSE 80
EXPOSE 9312

ENTRYPOINT ["/usr/src/app/bin/docker/run"]

CMD ["bundle", "exec", "unicorn", "-c", "config/unicorn.rb"]
