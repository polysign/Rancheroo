FROM ruby:2.3.1
MAINTAINER Georges Jentgen <georges@polysign.lu>

WORKDIR /var/app
COPY Gemfile /var/app
RUN gem install bundler
RUN bundle

COPY . /var/app
RUN chmod +x /var/app/bin/rancheroo

ENTRYPOINT ["/var/app/bin/rancheroo"]
