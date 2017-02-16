FROM ruby:2.3.1
RUN apt-get update -qq && apt-get upgrade -y && apt-get install -y build-essential && apt-get clean

ENV GOVUK_CONTENT_SCHEMAS_PATH /govuk-content-schemas
ENV MONGODB_URI mongodb://mongo/content-store
ENV PORT 3068
ENV RAILS_ENV development

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME

CMD bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -p $PORT -b '0.0.0.0'"
