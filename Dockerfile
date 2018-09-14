ARG DEBIAN_TAG=stretch

FROM debian:$DEBIAN_TAG

ARG DEBIAN_TAG=stretch
ARG NODEJS_VERSION=8.12.0
ARG POSTGRES_VERSION=9.6

ARG BUILD_DATE
ARG VCS_REF

MAINTAINER Oliver Salzburg <oliver.salzburg@gmail.com>

LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="MIT" \
    org.label-schema.name="FairManager Test Runner for GitLab CI" \
    org.label-schema.url="https://github.com/fairmanager/gitlab-build-image" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/fairmanager/gitlab-build-image"

# Enable backports (to install Docker)
RUN echo "deb http://ftp.debian.org/debian $DEBIAN_TAG-backports main" > /etc/apt/sources.list.d/backports.list && \
\
# Install essentials
	apt-get update --yes && \
	DEBIAN_FRONTEND=noninteractive apt-get install --yes \
		apt-transport-https \
		ca-certificates \
		curl \
		gnupg2 \
		software-properties-common \
		wget && \
\
# Install NodeJS
	curl --silent --location https://deb.nodesource.com/setup_8.x | bash - && \
	apt-get update --yes && \
	DEBIAN_FRONTEND=noninteractive apt-get install --yes nodejs=$NODEJS_VERSION* && \
\
# Make sure the docker group exists prior to installing Docker.
# This makes sure we get a fixed GID.
	groupadd --gid 999 docker && \
\
# Prepare Docker installation
	#APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key adv --keyserver hkp://pool.sks-keyservers.net --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
	curl --silent https://download.docker.com/linux/debian/gpg | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add - && \
	echo "deb https://download.docker.com/linux/debian $DEBIAN_TAG stable" > /etc/apt/sources.list.d/docker.list && \
\
# Prepare postgres installation
	curl --silent https://www.postgresql.org/media/keys/ACCC4CF8.asc | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add - && \
	echo "deb http://apt.postgresql.org/pub/repos/apt/ $DEBIAN_TAG-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
\
# Prepare yarn installation
	curl --silent https://dl.yarnpkg.com/debian/pubkey.gpg | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add - && \
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
	docker-ce \
	git \
	libfontconfig \
	libyaml-dev \
	postgresql-$POSTGRES_VERSION \
	postgresql-client-$POSTGRES_VERSION \
	postgresql-contrib-$POSTGRES_VERSION \
	python3 \
	python3-dev \
	python3-pip \
	rabbitmq-server \
	redis-server \
	sudo \
	yarn \
# These dependencies are mostly required for Chrome-related components used during testing.
	fonts-liberation \
	gconf-service \
	libappindicator1 \
	libasound2 \
	libatk1.0-0 \
	libc6 \
	libcairo2 \
	libcups2 \
	libdbus-1-3 \
	libexpat1 \
	libfontconfig1 \
	libgcc1 \
	libgconf-2-4 \
	libgdk-pixbuf2.0-0 \
	libglib2.0-0 \
	libgtk-3-0 \
	libnspr4 \
	libnss3 \
	libpango-1.0-0 \
	libpangocairo-1.0-0 \
	libstdc++6 \
	libx11-6 \
	libx11-xcb1 \
	libxcb1 \
	libxcomposite1 \
	libxcursor1 \
	libxdamage1 \
	libxext6 \
	libxfixes3 \
	libxi6 \
	libxrandr2 \
	libxrender1 \
	libxss1 \
	libxtst6 \
	lsb-release \
	xdg-utils && \
\
# Install AWS CLI
	pip3 install awscli

# Install other npm modules we usually need globally.
RUN npm install --global --unsafe-perm=true \
	bower \
	eslint \
	grunt-cli \
	gulp-cli \
	jshint \
	n \
	node-gyp \
	phantomjs-prebuilt \
	puppeteer && \
\
	# Delete apt cache, just to slightly trim down the image.
	rm -rf /var/lib/apt/lists/* && \
\
	echo && \
	echo --- Summary --- && \
	echo "- AWS CLI    :" `aws --version` && \
	echo "- Chromium   :" `/usr/lib/node_modules/puppeteer/.local-chromium/*/chrome-linux/chrome --version` && \
	echo "- Docker     :" `docker --version` && \
	echo "- ESLint     :" `eslint -v` && \
	echo "- git        :" `git --version` && \
	echo "- NodeJS     :" `node -v` && \
	echo "- npm        :" `npm -v` && \
	echo "- PhantomJS  :" `phantomjs -v` && \
	echo "- PostgreSQL :" `/usr/lib/postgresql/9.6/bin/postgres --version` && \
	echo "- Python     :" `python --version 2>&1` / `python3 --version` && \
	echo "- RabbitMQ   :" `dpkg -s rabbitmq-server | grep Version` && \
	echo "- Redis      :" `redis-server --version` && \
	echo "- yarn       :" `yarn --version`

