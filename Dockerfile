FROM debian:stable

MAINTAINER Oliver Salzburg <oliver.salzburg@gmail.com>

ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="MIT" \
    org.label-schema.name="FairManager Test Runner for GitLab CI" \
    org.label-schema.url="https://github.com/fairmanager/gitlab-build-image" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/fairmanager/gitlab-build-image"

# Enable backports (to install Docker)
RUN echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list && \
\
# Install essentials
	apt-get update --yes && \
	DEBIAN_FRONTEND=noninteractive apt-get install --yes \
		gnupg \
		apt-transport-https \
		ca-certificates \
		curl && \
\
# Install NodeJS
	curl --silent --location https://deb.nodesource.com/setup_8.x | bash - && \
	apt-get update --yes && apt-get install --yes nodejs && \
\
# Make sure the docker group exists prior to installing Docker.
# This makes sure we get a fixed GID.
	groupadd --gid 999 docker && \
\
# Prepare Docker installation
	apt-get purge "docker.io*" && \
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
	echo "deb https://apt.dockerproject.org/repo debian-stretch main" > /etc/apt/sources.list.d/docker.list && \
\
# Prepare postgres installation
	curl --silent https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
	echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
\
# Prepare yarn installation
	curl --silent https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
	echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
\
# Install more stuff we generally need.
# build-essentials are required to build some npm modules, so is git.
# Git is required anyway, because, well, we're going to pull our source code from VCS.
# libfontconfig is required for PhantomJS. Not everyone might need this, but we might as well prepare for
# it, to speed up builds that use it.
	apt-get update --yes && \
	DEBIAN_FRONTEND=noninteractive apt-get install --yes \
	build-essential \
	docker-engine \
	git \
	libfontconfig \
	libyaml-dev \
	postgresql-9.6 \
	postgresql-client-9.6 \
	postgresql-contrib-9.6 \
	python3 \
	python3-dev \
	python3-pip \
	rabbitmq-server \
	redis-server \
	sudo \
	yarn && \
\
# Install AWS CLI and docker-compose
	pip3 install awscli docker-compose
\
# Install other npm modules we usually need globally.
RUN npm install --global --no-audit --no-package-lock --unsafe-perm \
	bower \
	eslint \
	grunt-cli \
	gulp-cli \
	jshint \
	n \
	node-gyp \
	phantomjs-prebuilt && \
\
	# Delete apt cache, just to slightly trim down the image.
	rm -rf /var/lib/apt/lists/* && \
\
	echo && \
	echo --- Summary --- && \
	echo aws        : `aws --version` && \
	echo Docker     : `docker --version` && \
	echo NodeJS     : `node -v` && \
	echo npm        : `npm -v` && \
	echo PostgreSQL : `/usr/lib/postgresql/9.6/bin/postgres --version` && \
	echo Python     : `python --version` / `python3 --version` && \
	echo Redis      : `redis-server --version` && \
	echo yarn       : `yarn --version`

