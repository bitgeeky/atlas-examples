Setup Wordpress on AWS
===================
This repository and walkthrough guides you through deploying a Wordpress Blog/Application on AWS.

General Setup
-------------
1. Clone this repository
2. Create an Atlas account
3. Generate an [Atlas token](https://atlas.hashicorp.com/settings/tokens) and save as environment variable. 
`export ATLAS_TOKEN=<your_token>`
4. In the Vagrantfile, Packer files `lamp_stack.json` and Terraform file `wordpress_infra.tf` you need to replace all instances of `<username>`,  `YOUR_ATLAS_TOKEN`, `YOUR_SECRET_HERE`, and `YOUR_KEY_HERE` with your Atlas username, Atlas token, and AWS keys.

Configuring Wordpress Infrastructure.
-----------------------------------------------
The example requires to deploy a LAMP stack on AWS machine using Terraform and Packer and finally  the Wordpress application can be pushed using Vagrant and then linked to the existing build configuration.

Step 1: Build an Apache+MySQL+PHP AMI
---------------------
1. Build an AMI with Apache, MySQL and PHP installed. To do this, run `packer push -create lamp_stack.json` in the ops directory. This will send the build configuration to Atlas so it can remotely build your AMI with Apache, MySQL and PHP installed.

2. View the status of your build in the Operations tab of your [Atlas account](atlas.hashicorp.com/operations).

3. This creates an AMI with Apache, MySQL and PHP installed, and now you need to send the actual Wordpress application code to Atlas and link it to the build configuration. To do this, simply run `vagrant push` in the app directory. This will send your Wordpress application. Then link the Wordpress application with the Apache+MySQL+PHP build configuration by clicking on your build configuration, then 'Links' in the left navigation. Complete the form with your username, 'wordpress-example' as the application name, and '/app' as the destination path.

4. Now that your application and build configuration are linked, simply rebuild the Apache+MySQL+PHP after adding the given below configuration code to `lamp_stack.json` and you will have a fully-baked AMI with Apache, MySQL and PHP installed and your application code in place.

Add application configuration to `lamp_stack.json` in `provisioners` block.
----------------------------------------------------------------------------
```
{
    "type": "shell",
    "inline": [
        "sleep 30",
        "sudo mv /tmp/app/* /var/www/html/",
        "sudo chmod -R 775  /var/www/html/",
        "mysql -uroot -ppassword -e 'CREATE DATABASE blog'"
    ]
}
```

Caution !
----------
You will want to change permissions for `/var/www/html` depending on your production environment.

Step 4: Deploy to AWS
--------------------------
1. To deploy the Wordpress application, all you need to do is run `terraform apply` in the ops/terraform folder. Be sure to run `terraform apply` only on the artifacts first. The easiest way to do this is comment out the `aws_instance` resources and then run `terraform apply`. Once the artifacts are created, just uncomment the `aws_instance` resources and run `terraform apply` on the full configuration.

Final Step: Test Wordpress Blog
--------------------------------
1. Navigate to the Public IP of your Wordpress server. Run `terraform show` to easily find this information. You should see an Apache welcome page. Navigate to <public_ip>/wordpress to show your application code.
2. That's it! You just deployed a Wordpress Blog/Application. Now whenever you make a change, just run `vagrant push` in the app folder to build new artifacts, then run `terraform apply` in the ops/terraform folder to deploy them out.
