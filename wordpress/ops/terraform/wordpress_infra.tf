# Setup basic LAMP stack infra to deploy wordpress.

provider "aws" {
    access_key = "YOUR_ACCESS_KEY"
    secret_key = "YOUR_SECRET_KEY"
    region = "us-east-1"
}

resource "atlas_artifact" "wordpress-example" {
    name = "<username>/lamp_stack"
    type = "aws.ami"
}


 resource "aws_security_group" "allow_traffic" {
  name = "allow_traffic"
    description = "Allow all inbound tcp traffic"

  ingress {
      from_port = 0
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "wordpress-example" {
   instance_type = "t2.micro"
    ami = "${atlas_artifact.wordpress-example.metadata_full.region-us-east-1}"
    security_groups = ["${aws_security_group.allow_traffic.name}"]

    # This will create 1 instance
    count = 1
    lifecycle = {
      create_before_destroy = true
    }
}
