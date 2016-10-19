FROM debian:stable

MAINTAINER Oliver Salzburg <oliver.salzburg@gmail.com>

ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="MIT" \
    org.label-schema.name="Docker image for CI in Strider" \
    org.label-schema.url="https://github.com/fairmanager/strider-docker-slave" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/fairmanager/strider-docker-slave"

# Enable backports (to install Docker)
RUN echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list && \

# Install essentials
	apt-get update --yes && \
	DEBIAN_FRONTEND=noninteractive apt-get install --yes \
		apt-transport-https \
		ca-certificates \
		curl && \

# Install NodeJS
	curl --silent --location https://deb.nodesource.com/setup_6.x | bash - && \
	apt-get update --yes && apt-get install --yes nodejs && \

# Update npm
	npm install --global npm && \

# Make sure the docker group exists prior to installing Docker.
# This makes sure we get a fixed GID.
	groupadd --gid 999 docker && \

# Prepare Docker installation
	apt-get purge "docker.io*" && \
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
	echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list && \

# Prepate postgres installation
	curl --silent https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
	echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \

# Install more stuff we generally need.
# build-essentials are required to build some npm modules, so is git.
# Git is required anyway, because, well, we're going to pull our source code from VCS.
# libfontconfig is required for PhantomJS. Not everyone might need this, but we might as well prepare for
# it, to speed up builds that use it.
# sudo is installed to allow the strider user to run commands as root.
	apt-get update --yes && \
	DEBIAN_FRONTEND=noninteractive apt-get install --yes \
	build-essential \
	docker-engine \
	git \
	libfontconfig \
	postgresql \
	postgresql-client \
	postgresql-contrib \
	python \
	python-pip \
	rabbitmq-server \
	redis-server \
	sudo && \

# Install AWS CLI
	pip install awscli && \

# Setup workspace and user. This is expected by Strider
	adduser --home /home/strider --disabled-password --gecos "" strider && \
	mkdir --parents /home/strider/workspace && \
	chown --recursive strider /home/strider && \
	gpasswd --add strider docker && \
	gpasswd --add strider sudo

# Install our sudoers file. It allows members of the sudo group to use sudo without entering their password.
# The latter is important, because we want to allow strider to use sudo and strider has no password set.
ADD .docker/sudoers /etc/sudoers

# Install supervisord
RUN apt-get update --yes && \
	DEBIAN_FRONTEND=noninteractive apt-get install --yes supervisor && \
	mkdir --parents /var/log/supervisor && \
	mkdir --parents /etc/supervisor/conf.d

# write-to-file is expected to exist by strider-docker-gitane-camo
# which will use the command to drop an SSH key into the container
ADD .docker/write-to-file /usr/local/bin/
# Make sure SSH uses the dropped keyfile.
ADD .docker/ssh.sh /home/strider/

# Install the daemon that accepts the Strider inputs
ADD .docker/slave/* /home/strider/slave/
WORKDIR /home/strider/slave
RUN npm install --global

# Drop our default .npmrc, which allows us to set a private npm token
# through the environment plugin, using the NPM_TOKEN variable.
# Do this *after* any npm commands, because without the NPM_TOKEN set
# all npm interaction will likely fail!
ADD .docker/npmrc /home/strider/.npmrc

# Drop our .profile
ADD .docker/profile /home/strider/.profile

# Install other npm modules we usually need globally.
RUN npm install --global \
	bower \
	eslint \
	grunt-cli \
	gulp-cli \
	jshint \
	n \
	node-gyp && \

	# Delete apt cache, just to slightly trim down the image.
	rm -rf /var/lib/apt/lists/*

# Run the slave
# Additional background services can be configured by adding
# a supervisor config file to the config directory
# (/etc/supervisor/conf.d/)
WORKDIR /home/strider/workspace
CMD service docker start || supervisord --configuration /etc/supervisor/supervisord.conf && su strider --command ". ~/.profile && strider-docker-slave"
