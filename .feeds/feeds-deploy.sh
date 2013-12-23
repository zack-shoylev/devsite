#!/bin/bash

# This script assumes you've created this server with a key pair. If you haven't, you're not getting back in.
# curl -sS https://raw.github.com/rackerlabs/devsite/master/.feeds/feeds-deploy.sh | bash

# Switch to feeder user
adduser --shell /bin/bash --gecos "User for managing feeds" --disabled-password --home /home/feeder feeder
adduser feeder sudo
grep -q "^#includedir.*/etc/sudoers.d" /etc/sudoers || echo "#includedir /etc/sudoers.d" >> /etc/sudoers
( umask 226 && echo "feeder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/50_feeder_sh )
mkdir /home/feeder/.ssh
cp .ssh/authorized_keys /home/feeder/.ssh/
chown -R feeder:feeder /home/feeder/.ssh
su feeder
cd

# Lock it down
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sudo service ssh restart
sudo ufw allow 22
sudo ufw --force enable
sudo apt-get -y install fail2ban

# Upgrade and set unattended upgrades
sudo apt-get -y update; sudo apt-get -y upgrade
sudo apt-get -y install unattended-upgrades
sudo sed -i 's/Download-Upgradeable-Packages "0";/Download-Upgradeable-Packages "1";/g' /etc/apt/apt.conf.d/10periodic
sudo sed -i 's/AutocleanInterval "0";/AutocleanInterval "7";/g' /etc/apt/apt.conf.d/10periodic
echo 'APT::Periodic::Unattended-Upgrade "1";' | sudo tee -a /etc/apt/apt.conf.d/10periodic

# GitHub config, clone devsite, and install hub
cd
sudo apt-get -y install git
git config --global user.name drg-bot
git config --global user.email sdk-support@rackspace.com
echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
git clone git@github.com:rackerlabs/devsite.git

sudo apt-get -y install ruby1.9.1
sudo gem install bundler rake
git clone https://github.com/github/hub.git
cd hub
bundle install
sudo rake install prefix=/usr/local

# Setup Planet Venus (feed aggregator)
cd
sudo apt-get -y install planet-venus
mkdir planet
cd planet
planet --create api
cp /home/feeder/devsite/.feeds/planet-api.ini api/planet.ini
planet --create sdk
cp /home/feeder/devsite/.feeds/planet-sdk.ini sdk/planet.ini

# Setup WebPageToAtomFeed
cd
sudo apt-get -y install openjdk-7-jdk maven
git clone https://github.com/rackerlabs/WebPageToAtomFeed.git
cp /home/feeder/devsite/.feeds/WebPageToAtomFeed.properties /home/feeder/WebPageToAtomFeed/src/main/resources/
cd WebPageToAtomFeed/
mvn clean install

# Cron
cd
echo "0 14 * * * /home/feeder/devsite/.feeds/feeds-cron.sh" | crontab -
