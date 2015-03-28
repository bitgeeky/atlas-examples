Setup Discourse on AWS
===
This repository and walkthrough guides you through deploying Discourse forum on AWS using officially supported Docker installation. More details on the docker image installation method can be found in [Discourse install guide](https://github.com/discourse/discourse/blob/master/docs/INSTALL.md)

General setup
-------------
1. Clone this repository
2. Create an Atlas account
3. Generate an [Atlas token](https://atlas.hashicorp.com/settings/tokens) and save as an environment variable. 
`export ATLAS_TOKEN=<your_token>`
4. In the Packer and Terraform files `ops/discourse-artifact.json` and `ops/terraform/discourse-infra.tf` you need to replace all instances of `<username>`,  `YOUR_ATLAS_TOKEN`, `YOUR_SECRET_HERE`, and `YOUR_KEY_HERE` with your Atlas username, Atlas token, and AWS keys.

Introduction and Configuring Discourse
---
The only officially supported installs of Discourse are the Docker based installs. In this guide we will deploy Discourse forum on a `t2.micro` instance of AWS. For a 1 GB install it's advised to create a swap file but if you're using 2 GB+ memory, you can probably get by without a swap file. The `ops/scripts/create_swap.sh` creates a swap file and `ops/scripts/deploy.sh` deploys, bootstraps and starts the Discourse application. Discourse configuration is stored in `ops/configs/standalone.yml`.

Step 1: Edit Discourse Configuration
---
Edit the Discourse configuration at `ops/configs/standalone.yml`.

- Set `DISCOURSE_DEVELOPER_EMAILS` to your email address.

- Set `DISCOURSE_HOSTNAME` to `discourse.example.com`, this means you want your Discourse available at `http://discourse.example.com/`. You'll need to update the DNS A record for this domain with the IP address of your server.

- Place your mail credentials in `DISCOURSE_SMTP_ADDRESS`, `DISCOURSE_SMTP_PORT`, `DISCOURSE_SMTP_USER_NAME`, `DISCOURSE_SMTP_PASSWORD`. Be sure you remove the comment `#` character and space from the front of these lines as necessary.

- If you are using a 1 GB instance, set `UNICORN_WORKERS` to 2 and `db_shared_buffers` to 128MB so you have more memory room.

**Email is CRITICAL for account creation and notifications in Discourse. If you do not properly configure email before bootstrapping YOU WILL HAVE A BROKEN SITE!**

Step 2: Create an ATLAS artifact
---
Store the complete infrastructure configuration and the deployment scripts as an ATLAS artifact using Packer.

```
{
    "variables": {
        "aws_access_key": "YOUR_ACCESS_KEY",
        "aws_secret_key": "YOUR_SECRET_KEY"
    },
    "builders": [{
        "type": "amazon-ebs",
        "access_key": "{{user `aws_access_key`}}",
        "secret_key": "{{user `aws_secret_key`}}",
        "region": "us-east-1",
        "source_ami": "ami-9a562df2",
        "instance_type": "t2.micro",
        "ssh_username": "ubuntu",
        "ami_name": "discourse {{timestamp}}"
    }],
    "push": {
      "name": "<username>/discourse"
    },
    "provisioners": [
    {   
        "type": "shell",
        "inline": [
            "sudo mkdir /ops",
            "sudo chmod a+w /ops"
        ]
    },
    {   
        "type": "file",
        "source": ".",
        "destination": "/ops"
    },
    {
        "type": "shell",
        "scripts": [
            "scripts/create_swap.sh",
            "scripts/deploy.sh"
        ]
    }
    ],
    "post-processors": [
      {
        "type": "atlas",
        "artifact": "<username>/discourse",
        "artifact_type": "aws.ami",
        "metadata": {
          "created_at": "{{timestamp}}"
        }
      }
    ]
}
```

Run `packer push -create discourse-artifact.json` to build the ATLAS artifact.

Step 3: Deploy Infratsructure on AWS
---
Deploy the complete infrastructure stored as an ATLAS artifact by running `terraform apply` in `ops/terraform` directory. Make sure to allow `tcp` traffic on port `80` in your security group. If you don't have, you can create one.

```
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
```

Final Step: Register New Account and Become Admin
--------------------------------
1. Navigate to the Public IP of your Discourse forum. Run terraform show to easily find this information or alternatively navigate to the domain name you provided while configuring the DNS settings. You should see the default Discourse page.

2. That's it! You just deployed a Discourse forum on AWS. For post install maintenance and more Discourse features see [official Discourse guide](https://github.com/discourse/discourse/blob/master/docs/INSTALL-digital-ocean.md).

Troubleshooting/Debugging
----
For debugging puposes please see our [AWS-SSH-Setup guide](https://github.com/hashicorp/atlas-examples/tree/master/AWS-SSH-Setup).
