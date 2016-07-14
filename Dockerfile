FROM debian:stable

MAINTAINER Oliver Salzburg <oliver.salzburg@gmail.com>

# First things first...
RUN apt-get --yes update

# Install curl
RUN apt-get install --yes curl

# Install NodeJS
RUN curl --silent --location https://deb.nodesource.com/setup_4.x | bash -
RUN apt-get install --yes nodejs

# Update npm
RUN npm install --global npm

# Install more stuff we generally need
RUN apt-get install --yes build-essential git

# Setup workspace and user. This is expected by Strider
RUN adduser --home /home/strider --disabled-password --gecos "" strider
RUN mkdir --parents /home/strider/workspace
RUN chown --recursive strider /home/strider

# Get the slave
#RUN npm install --global strider-docker-slave@1.*.*

# Install supervisord
RUN apt-get install --yes supervisor && \
  mkdir --parents /var/log/supervisor && \
  mkdir --parents /etc/supervisor/conf.d

ADD ssh.sh /home/strider/
# write-to-file is expected to exist by strider-docker-gitane-camo
# which will use the command to drop an SSH key into the container
ADD write-to-file /usr/local/bin/
# Make sure SSH uses the dropped keyfile.
ENV GIT_SSH /home/strider/ssh.sh

# Install the slave
ADD slave/* /home/strider/slave/
WORKDIR /home/strider/slave
RUN npm install --global

# Run the slave
# Additional background services can be configured by adding
# a supervisor config file to the config directory
# (/etc/supervisor/conf.d/)
CMD supervisord --configuration /etc/supervisor/supervisord.conf && su strider --command "strider-docker-slave"

WORKDIR /home/strider/workspace
ENV HOME /home/strider
