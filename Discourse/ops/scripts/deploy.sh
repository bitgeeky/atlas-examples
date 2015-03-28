#!/bin/sh
sudo wget -qO- https://get.docker.io/ | sh
sudo mkdir /var/discourse
sudo git clone https://github.com/discourse/discourse_docker.git /var/discourse
sudo cp /ops/configs/standalone.yml /var/discourse/containers/app.yml
cd /var/discourse
sudo ./launcher bootstrap app
sudo ./launcher start app
