FROM ruby:2.4

ENV BUNDLE_PATH="/app/.bundle"
ENV GEM_HOME="/app/.bundle"

WORKDIR /app

COPY .bundle .bundle
COPY Gemfile .
COPY Gemfile.lock .
COPY run.rb .

ENTRYPOINT ["ruby", "/app/run.rb"]
