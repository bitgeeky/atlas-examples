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
