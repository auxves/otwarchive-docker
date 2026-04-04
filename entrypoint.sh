#!/usr/bin/env bash

export RUBYOPT="-W0"

DB_HOST=${DB_HOST:-db}
DB_USERNAME=${DB_USERNAME:-root}
DB_PASSWORD=${DB_PASSWORD:-change_me}

function database_exists() {
    local OUTPUT=$(mysql -h $DB_HOST -u $DB_USERNAME --password="$DB_PASSWORD" \
        -e "show databases like '$1';")

    [ -n "$OUTPUT" ]
}

function seed_db_if_fresh() {
    if database_exists "otwarchive_${RAILS_ENV}"; then
        return
    fi

    bundle exec rake db:create db:schema:load

    if [[ "$RAILS_ENV" =~ ^(development|test)$ ]]; then
        bundle exec rake db:otwseed

        bundle exec rake search:index_tags
        bundle exec rake search:index_works
        bundle exec rake search:index_pseuds
        bundle exec rake search:index_bookmarks
        bundle exec rake search:index_admin_users
        bundle exec rake search:index_collections
    fi

    bundle exec rake skins:load_site_skins
}

if [ ! -f /otwa/config/database.yml ]; then
    sed "s/host: db/host: ${DB_HOST}/g" /otwa/config/docker/database.yml | \
    sed "s/username: root/username: ${DB_USERNAME}/g" | \
    sed "s/password: change_me/password: ${DB_PASSWORD}/g" > /otwa/config/database.yml
fi

if [ ! -f /otwa/config/local.yml ]; then
    sed "s/ES_URL: es:9200/ES_URL: ${ES_URL:-es:9200}/g" /otwa/config/docker/local.yml | \
    sed "s/MEMCACHED_SERVERS: mc:11211/MEMCACHED_SERVERS: ${MEMCACHED_SERVERS:-mc:11211}/g" > /otwa/config/local.yml

    if [ -n "$EXTRA_CONFIG" ]; then
        echo >> /otwa/config/local.yml
        echo "$EXTRA_CONFIG" >> /otwa/config/local.yml
    fi
fi

if [ ! -f /otwa/config/redis.yml ]; then
    sed "s/redis:6379/${REDIS_HOST:-redis}:6379/g" /otwa/config/docker/redis.yml > /otwa/config/redis.yml
fi

# Add custom environment config
sed -i '/Rails\.application\.configure do/a\
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "error")\
  config.hosts << /.*/
' /otwa/config/environments/$RAILS_ENV.rb

seed_db_if_fresh

# Migrate database
bundle exec rake db:migrate

# Start indexing jobs
(
    export QUEUE='*'
    bundle exec rake environment resque:scheduler &
    bundle exec rake environment resque:work
) &

# Start rails server
bundle exec rails server -p 3000 -b 0.0.0.0
