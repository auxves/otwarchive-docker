# Automated docker images for otwarchive

This repo builds docker images of the [otwarchive](https://github.com/otwcode/otwarchive) software.

## Configuration

### Environment Variables

#### Database Configuration

- `DB_HOST`: Database host (default: `db`)
- `DB_USERNAME`: Database username (default: `root`)
- `DB_PASSWORD`: Database password (default: `change_me`)

#### External Services

- `ES_URL`: Elasticsearch URL (default: `es:9200`)
- `MEMCACHED_SERVERS`: Memcached servers (default: `mc:11211`)
- `REDIS_HOST`: Redis host (default: `redis`)

#### Application Settings

- `RAILS_ENV`: Rails environment (`development`, `test`, `production`) (default: `development`)
- `RAILS_LOG_LEVEL`: Logging level (default: `error`)
- `OTWA_AUTOSEED`: Enable automatic database seeding (set to 1 to wipe and seed the database on container startup)
