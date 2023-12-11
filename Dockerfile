FROM ubuntu:jammy
ENV POSTGRES_USER=postgres
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
RUN apt-get update && apt-get install -y \
    ruby-full \
    make \ 
    gcc \
    libpq-dev \
    tzdata \
    gettext

COPY ./redmine-5.0.7 /opt/redmine-5.0.7
WORKDIR /opt/redmine-5.0.7/
RUN gem install bundler && \
    chown -R $USER: /opt/redmine-5.0.7 && \
    bundle config set --local without 'development test' && \
    echo "# Gemfile.local\ngem 'puma'" >> Gemfile.local && \
    bundle install

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT [ "entrypoint.sh" ]
EXPOSE 3000