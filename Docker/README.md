Docker Container
===================
This repository and walkthrough guides you through deploying a NGINX Docker container on AWS.

General setup
-------------
1. Clone this repository
2. Create an [Atlas account](https://atlas.hashicorp.com/account/new?utm_source=github&utm_medium=examples&utm_campaign=lamp)
3. Generate an [Atlas token](https://atlas.hashicorp.com/settings/tokens) and save as environment variable. 
`export ATLAS_TOKEN=<your_token>`
4. In the Vagrantfile, Packer file `docker.json` and Terraform file `terraform/docker-infra.tf` you need to replace all instances of `<username>`,  `YOUR_ATLAS_TOKEN`, `YOUR_SECRET_HERE`, and `YOUR_KEY_HERE` with your Atlas username, Atlas token, and AWS keys.

Introduction and Configuring a Docker container
-----------------------------------------------
In this example we use the official docker image for [nginx](https://registry.hub.docker.com/_/nginx/) to deploy it as a container on AWS. Terraform supports [docker provider](https://terraform.io/docs/providers/docker) which can further communicate with a host using docker api. The default port for all communication is `2375` and default protocol is `tcp`.
It is advised not to use `tcp` communication on a production environment and make only secure comunication using [tls](https://docs.docker.com/articles/https/).

Step 1: Build a Docker AMI
---------------------
Build an AMI with Docker installed and configured daemon for listening to remote api calls . To do this, remove file provisioner from `docker.json` and run `packer push -create docker.json` in the ops directory. This will send the build configuration to Atlas so it can remotely build your AMI with Docker installed.
```
{
    "type": "file",
    "source": "/packer/app",
    "destination": "/tmp"
}
```

View the status of your build in the Operations tab of your [Atlas account](atlas.hashicorp.com/operations). Key point to note here is that the ami build process runs a script `scripts/install-docker.sh` to install docker and the configure daemon to listen to remote `tcp` api calls on port `2375`.
```
echo 'DOCKER_OPTS="-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock"'| sudo tee /etc/default/docker
sudo service docker restart
```

This creates an AMI with Docker installed, and now you need to send the actual application code to Atlas and link it to the build configuration. To do this, simply run `vagrant push` in the app directory. This will send your application, which is just the `index.html` file for now. Then link the application with the Docker build configuration by clicking on your build configuration, then 'Links' in the left navigation. Complete the form with your username, 'docker' as the application name, and '/app' as the destination path.
4. Now that your application and build configuration are linked, simply rebuild the Docker configuration with file provisioner in place and you will have a fully-baked AMI with Docker installed with daemon listening to api calls and your application code in place.

Step 2: Create AWS instance
--------------------------
1. To create aws instance, all you need to do is run `terraform apply` in the ops/terraform folder. Be sure to run `terraform apply` only on the artifacts first. The easiest way to do this is comment out the `aws_instance` resources and then run `terraform apply`. Once the artifacts are created, just uncomment the `aws_instance` resources and run `terraform apply` on the full configuration. Remember to keep the docker provider and container configuration still in comments. 
```
provider "atlas" {
    token = "ATLAS_TOKEN_HERE"
}

provider "aws" {
    access_key = "ACCESS_KEY_HERE"
    secret_key = "SECRET_KEY_HERE"
    region = "us-east-1"
}

resource "atlas_artifact" "docker" {
    name = "<username>/docker"
    type = "aws.ami"
}

resource "aws_security_group" "allow_tcp" {
  name = "allow_tcp"
    description = "Allow all inbound tcp traffic"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port = 2375
      to_port = 2375
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "docker" {
    instance_type = "t2.micro"
    ami = "${atlas_artifact.docker.metadata_full.region-us-east-1}"
    security_groups = ["${aws_security_group.allow_tcp.name}"]

    # This will create 1 instances
    count = 1
}

/*
provider "docker" {
    # Replace it with public ip of docker host.
    host = "tcp://pubic_ip:2375/"
}

resource "docker_container" "nginx" {
  name = "nginx"
  image = "${docker_image.nginx.latest}"
  
  ports = {
        internal = "80"
        external = "80"
  }
  
  volumes = {
        container_path = "/usr/share/nginx/html"
        host_path = "/home/ubuntu/site"
  }
}

resource "docker_image" "nginx" {
    name = "nginx:latest"
}
*/
```

To check if docker daemon is running and listening to api calls properly run `$ docker -H tcp://public_ip:2375 images` locally by replacing `public_ip` with actual public ip of your aws instance which is also the docker daemon host.
You should see something like this.
```
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
nginx               latest              224873bdcaa1        10 days ago         93.44 MB
```
Similarly you can run all docker commands locally by specifying `-H` parameter like `$ docker -H tcp://public_ip:2375 ps`.

Step 3: Deploy Docker Container
------------------------
Run `terraform show` to get `public_ip` of aws instance and replace it in docker host provider to communicate with docker daemon.

Map the docker container port `internal` to host port `external`.
```
ports = {
    internal = "80"
    external = "80"
}
```

Mount host volume containing application in docker container.
```
volumes = {
    container_path = "/usr/share/nginx/html"
    host_path = "/home/ubuntu/site"
}
```
Uncomment the above code and run `terraform apply` to deploy nginx docker container.

Step 4: Final Step
------------------------
1. Navigate to the Public IP of your AWS instance. Run `terraform show` to easily find this information.
2. That's it! You just deployed a Docker container on AWS. Now whenever you make a change, just run `vagrant push` in the app folder to build new artifacts, then run `terraform apply` in the ops/terraform folder to deploy them out.

Production Deployment 
------------------
Its always advised not to use `tcp` protocol to communicate with docker daemon and use `tls` instead. Detailed documentation for advanced users can be found [here](https://docs.docker.com/articles/https/).
Use optional parameter `cert_path` in docker provider or set environment variable `DOCKER_CERT_PATH`  to provide path to certificates.

Troubleshooting/Debugging
----
For debugging puposes please see our [AWS-SSH-Setup guide](https://github.com/hashicorp/atlas-examples/tree/master/AWS-SSH-Setup).
