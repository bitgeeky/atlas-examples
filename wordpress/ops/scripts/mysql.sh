sudo apt-get -y update

# set root password
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'

# Install requirements
sudo apt-get install -y -qq \
    mysql-server
