provider "aws" {
    access_key = "YOUR_ACCESS_KEY"
    secret_key = "YOUR_SECRET_KEY"
    region = "us-east-1"
}

resource "atlas_artifact" "php" {
    name = "<username>/apache-php"
    type = "aws.ami"
}

resource "atlas_artifact" "mysql" {
    name = "<username>/mysql"
    type = "aws.ami"
}

resource "aws_security_group" "allow_all" {
  name = "allow_all"
    description = "Allow all inbound traffic"

  ingress {
      from_port = 0
      to_port = 65535
      protocol = "all"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "php" {
    instance_type = "t2.micro"
    ami = "${atlas_artifact.php.metadata_full.region-us-east-1}"
    security_groups = ["${aws_security_group.allow_all.name}"]

    # This will create 1 instance
    count = 1
    lifecycle = {
      create_before_destroy = true
    }
}

resource "aws_instance" "mysql" {
    instance_type = "t2.micro"
    ami = "${atlas_artifact.mysql.metadata_full.region-us-east-1}"
    security_groups = ["${aws_security_group.allow_all.name}"]

    # This will create 1 instances
    count = 1
    lifecycle = {
      create_before_destroy = true  
    }
}