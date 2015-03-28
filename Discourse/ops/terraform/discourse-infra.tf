provider "aws" {
    access_key = "YOUR_ACCESS_KEY"
    secret_key = "YOUR_SECRET_KEY"
    region = "us-east-1"
}

resource "atlas_artifact" "discourse" {
    name = "<username>/discourse"
    type = "aws.ami"
}

resource "aws_security_group" "allow_tcp" {
  name = "allow_tcp"
    description = "Allow tcp traffic on port 80"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "discourse" {
    instance_type = "t2.micro"
    ami = "${atlas_artifact.discourse.metadata_full.region-us-east-1}"
    security_groups = ["${aws_security_group.allow_tcp.name}"]

    # This will create 1 instance
    count = 1
    lifecycle = {
      create_before_destroy = true
    }
}
