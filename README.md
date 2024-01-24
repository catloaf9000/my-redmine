# Learning how to dockerize application - Redmine

## Usage

```bash
docker run --name redmine-postgres-1 -e POSTGRES_PASSWORD=mysecretpassword -d -p 5432:5432 postgres:14
```

## How I did it:

### Part 1: install Redmine by hands in VM ubuntu 22.04 LTS

I'll use vagrant VM for application server and postgres docker container on host
[Official installation guide](https://www.redmine.org/projects/redmine/wiki/RedmineInstall)

#### Step 1 - Install Ruby and Redmine application

On vagrant's VM:
```bash
sudo apt-get update
sudo apt-get install -y ruby-full
# dependencies for ruby's gems
sudo apt-get install -y make gcc libpq-dev 
wget -P /tmp/ https://www.redmine.org/releases/redmine-5.0.7.tar.gz
sudo tar -xzf /tmp/redmine-5.0.7.tar.gz -C /opt/
```

#### Step 2 - Run postgres in docker and create db and user

On host: 
```bash
docker pull postgres:14
docker run --name redmine-postgres -e POSTGRES_PASSWORD=mysecretpassword -d -p 5432:5432 postgres:14
psql -h localhost -U postgres
```

```sql
CREATE ROLE redmine LOGIN ENCRYPTED PASSWORD 'my_password' NOINHERIT VALID UNTIL 'infinity';
CREATE DATABASE redmine WITH ENCODING='UTF8' OWNER=redmine;
exit
```

#### Step 3 - Configure database connection

On VM:

```
sudo cp /opt/redmine-5.0.7/config/database.yml.example  /opt/redmine-5.0.7/config/database.yml
sudo vim /opt/redmine-5.0.7/config/database.yml
```

Edit `production` block - comment out mysql blocks and make postgres configuration:

```
production:
  adapter: postgresql
  database: redmine
  host: 10.0.2.2
  username: postgres
  password: "mysecretpassword" 
  encoding: utf8
  schema_search_path: public
```

> Magic IP of vagrant's host is 10.0.2.2

Save and quit.

#### Step 4 - Install dependencies

```bash
cd /opt/redmine-5.0.7/
sudo gem install bundler
sudo chown -R $USER: /opt/redmine-5.0.7
# mkdir /var/lib/gems
# sudo chown -R $USER: /var/lib/gems
sudo bundle config set --local without 'development test' 
echo "# Gemfile.local\ngem 'puma'" >> Gemfile.local
sudo bundle install
```

#### Step 5 - Session store secret generation

```bash
sudo bundle exec rake generate_secret_token
```

#### Step 6 - Database schema objects creation

```bash
RAILS_ENV=production bundle exec rake db:migrate
```

#### Step 7 - Database default data set

```bash
RAILS_ENV=production REDMINE_LANG=en bundle exec rake redmine:load_default_data
```

#### Step 8 - File system permissions

```bash
mkdir -p tmp tmp/pdf public/plugin_assets
sudo chown -R vagrant:vagrant files log tmp public/plugin_assets
sudo chmod -R 755 files log tmp public/plugin_assets
sudo find files log tmp public/plugin_assets -type f -exec chmod -x {} +
```

#### Step 9 - Test the installation

```bash
bundle exec rails server -u puma -e production
```

### Part 2 - Containerize

```bash
docker run --name redmine-postgres-1 -e POSTGRES_PASSWORD=mysecretpassword -d -p 5432:5432 postgres:14
```

```bash
docker run --name redmine -e POSTGRES_HOST=host.docker.internal -e POSTGRES_PASSWORD=mysecretpassword -p 80:3000 -it my-redmine
```