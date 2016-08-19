# Strider Docker Slave
[![](https://images.microbadger.com/badges/version/fairmanager/strider-docker-slave.svg)](http://microbadger.com/images/fairmanager/strider-docker-slave "Get your own version badge on microbadger.com")

The concept of this image is for it to run a single process that accepts input on stdin.
The input will be JSON formatted commands for it to run.

The hosting application (Stider) can pipe these JSON inputs into the running container.
Results of the executed commands are emitted as JSON again and are read back by Strider.
