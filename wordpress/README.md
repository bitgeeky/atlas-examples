Setup Wordpress on AWS
===================
This repository and walkthrough guides you through deploying a Wordpress Blog/Application on AWS.

General setup
-------------
1. Clone this repository
2. Create an Atlas account
3. Generate an [Atlas token](https://atlas.hashicorp.com/settings/tokens) and save as environment variable. 
`export ATLAS_TOKEN=<your_token>`
4. In the Vagrantfile, Packer files `apache-php.json` and `mysql.json`, Terraform file `lamp.tf`, and Consul upstart script `consul_client.conf` you need to replace all instances of `<username>`,  `YOUR_ATLAS_TOKEN`, `YOUR_SECRET_HERE`, and `YOUR_KEY_HERE` with your Atlas username, Atlas token, and AWS keys.

Configuring Wordpress Infrastructure.
-----------------------------------------------
The example requires to deploy a LAMP stack on AWS machine using Terraform and Packer and finally  the Wordpress application can be pushed using Vagrant and then linked to the existing build configuration.


Step 1: Create a Consul Cluster
-------------------------
1. For Consul Template to work for LAMP, we first need to create a Consul cluster. You can follow [this walkthrough](https://github.com/hashicorp/atlas-examples/tree/master/consul) to guide you through that process. 

Step 2: Deploying a LAMP stack
-------------------------
1. After creating a Consul cluster we need to deploy LAMP on our infrastructure and link the MySQL ami with the php-apache ami using Consul cluster. You can follow [this walkthrough](https://github.com/hashicorp/atlas-examples/tree/master/LAMP) to guide you through that process. 


Step 3: Deploying Wordpress Application/Blog
-------------------------
After deploying a LAMP stack all we need to do is configure the database settings to deploy the actual wordpress application.
Add the application code to `/app`. Change the database configuration in `wp-config` file of default wordpress application.
Change the following parameters as:

```
$username = "apache";
$password = "password";{{range service "mysql.database"}}
$hostname = "{{.Address}}"{{end}};


define('DB_NAME', 'blog');

/** MySQL database username */
define('DB_USER', $username);

/** MySQL database password */
define('DB_PASSWORD', $password);

/** MySQL hostname */
define('DB_HOST', $hostname);

```
Send the application code to ATLAS using `vagrant push`.

Step 4: Creating `blog` database
-------------------------
Modify the `mysql.sh` script in `ops/scripts` to add the command to create `blog` database.
```
mysql -uroot -ppassword -e 'CREATE DATABASE blog'
```
Update the mysql by doing `packer push mysql.json`.
Update apache-php ami to link with the new application code by running `packer push apache-php.json`.

Step 5: Deploy to AWS.
-------------------------
Finally run `terraform apply` to deploy the application code to AWS with updated mysql configuration.

Final Step: Test Wordpress Blog
--------------------------------
1. Navigate to the Public IP of your Wordpress server. Run `terraform show` to easily find this information. You should see an Apache welcome page. Navigate to <public_ip>/wordpress to show your application code.
2. That's it! You just deployed a Wordpress Blog/Application. Now whenever you make a change, just run `vagrant push` in the app folder to build new artifacts, then run `terraform apply` in the ops/terraform folder to deploy them out.

Local Development
------------------
This project uses [Scotch Box](https://box.scotch.io/) for local development with [Vagrant](https://vagrantup.com). 
