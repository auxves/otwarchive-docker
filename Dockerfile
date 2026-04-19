FROM ruby:3.4.6

# Install additional packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    calibre \
    default-mysql-client \
    libvips \
    shared-mime-info \
    zip && \
    apt-get clean

WORKDIR /otwa

# Install ruby packages
RUN gem install bundler -v 2.6.9

COPY otwa/Gemfile .
COPY otwa/Gemfile.lock .

# Use a mirror of devise that preserves prior refs
RUN sed -i 's#https://github.com/otwcode/devise#https://forge.auxves.dev/mirrors/devise#' Gemfile Gemfile.lock

ARG TARGETARCH

RUN --mount=type=cache,target=/var/cache/bundle,id=bundle-${TARGETARCH},sharing=locked \
    bundle config set deployment true \
    && bundle config set path "/var/cache/bundle" \
    && bundle config set without "development test" \
    && bundle install -j "$(getconf _NPROCESSORS_ONLN)" \
    && cp -r /var/cache/bundle /bundle \
    && bundle config path /bundle

ADD --exclude=otwa/.git otwa /otwa
COPY entrypoint.sh /bin/entrypoint.sh

EXPOSE 3000

CMD [ "bash", "/bin/entrypoint.sh" ]
