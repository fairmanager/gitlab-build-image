FROM debian:stable

MAINTAINER Oliver Salzburg <oliver.salzburg@gmail.com>

# Enable backports (to install Docker)
RUN echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list

# Install curl
RUN apt-get update --yes && apt-get install --yes curl

# Install NodeJS
RUN curl --silent --location https://deb.nodesource.com/setup_4.x | bash -
RUN apt-get update --yes && apt-get install --yes nodejs

# Update npm
RUN npm install --global npm

# Install more stuff we generally need.
# build-essentials are required to build some npm modules, so is git.
# Git is required anyway, because, well, we're going to pull our source code from VCS.
# libfontconfig is required for PhantomJS. Not everyone might need this, but we might as well prepare for
# it, to speed up builds that use it.
RUN apt-get update --yes && apt-get install --yes \
	build-essential \
	docker.io \
	git \
	libfontconfig

# Start Docker
RUN service docker start

# Setup workspace and user. This is expected by Strider
RUN adduser --home /home/strider --disabled-password --gecos "" strider
RUN mkdir --parents /home/strider/workspace
RUN chown --recursive strider /home/strider

# Install supervisord
RUN apt-get update --yes && apt-get install --yes supervisor && \
	mkdir --parents /var/log/supervisor && \
	mkdir --parents /etc/supervisor/conf.d

# write-to-file is expected to exist by strider-docker-gitane-camo
# which will use the command to drop an SSH key into the container
ADD write-to-file /usr/local/bin/
# Make sure SSH uses the dropped keyfile.
ADD ssh.sh /home/strider/

# Install the daemon that accepts the Strider inputs
ADD slave/* /home/strider/slave/
WORKDIR /home/strider/slave
RUN npm install --global

# Drop our default .npmrc, which allows us to set a private npm token
# through the environment plugin, using the NPM_TOKEN variable.
# Do this *after* any npm commands, because without the NPM_TOKEN set
# all npm interaction will likely fail!
ADD npmrc /home/strider/.npmrc

# Drop our .profile
ADD profile /home/strider/.profile

# Install other npm modules we usually need globally.
RUN npm install --global \
	bower \
	eslint \
	grunt-cli \
	gulp-cli \
	jshint \
	n \
	node-gyp

# Run the slave
# Additional background services can be configured by adding
# a supervisor config file to the config directory
# (/etc/supervisor/conf.d/)
WORKDIR /home/strider/workspace
CMD supervisord --configuration /etc/supervisor/supervisord.conf && su strider --command ". ~/.profile && strider-docker-slave"
