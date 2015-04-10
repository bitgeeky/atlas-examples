wget -qO- https://get.docker.io/ | sh
echo 'DOCKER_OPTS="-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock"'| sudo tee /etc/default/docker
sudo service docker restart
