#!/bin/sh
cd /opt/redmine-5.0.7/
CONTAINER_FIRST_STARTUP="CONTAINER_FIRST_STARTUP"

if [ -z $POSTGRES_HOST ]; then
    cat >&2 <<-'EOE'
			Error: Database host is not specified.
			       You must specify POSTGRES_HOST as IP address or DNS name. 
			       For example, "-e POSTGRES_HOST=localhost" on "docker run".
	EOE
	exit 1
fi
if [ -z $POSTGRES_PASSWORD ]; then
    cat >&2 <<-'EOE'
			Error: Database password is not specified.
			       You must specify POSTGRES_PASSWORD to a non-empty value for the
			       superuser. For example, "-e POSTGRES_PASSWORD=password" on "docker run".
	EOE
	exit 1
fi

if [ ! -e /$CONTAINER_FIRST_STARTUP ]; then
    touch /$CONTAINER_FIRST_STARTUP
    cat ./config/database.yml.template | envsubst > ./config/database.yml
    bundle install # install db provider gem
    bundle exec rake generate_secret_token
    RAILS_ENV=production bundle exec rake db:migrate
    RAILS_ENV=production REDMINE_LANG=en bundle exec rake redmine:load_default_data
    mkdir -p tmp tmp/pdf public/plugin_assets
    find files log tmp public/plugin_assets -type f -exec chmod -x {} +
fi
bundle exec rails server -u puma -e production