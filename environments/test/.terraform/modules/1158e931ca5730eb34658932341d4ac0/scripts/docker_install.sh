#!/bin/bash -v

sudo su -

mkdir /var/log/tf/ ; chown -R ubuntu:ubuntu /var/log/tf/; chmod -R go+rw /var/log/tf

# Install utilities
# Ensure dependencies are installed
apt update > /var/log/tf/yum_install.log 2>&1
apt upgrade >> /var/log/tf/yum_install.log 2>&1
apt install -y yum       >> /var/log/tf/yum_install.log 2>&1
apt-get install -y tftp tftpd syslinux apache2 dhcpcd5
yum install -y epel-release   >> /var/log/tf/yum_install.log 2>&1
yum update -y epel-release    >> /var/log/tf/yum_install.log 2>&1
apt-get install -y python-pip \
    python-dev \
    git \
    libssl-dev \
    libffi6 \
    python-six \
    python-boto \
    python-jinja2 \
    python-demjson \
    apt-transport-https \
    python-software-properties \
    software-properties-common \
    ansible >> /var/log/tf/yum_install.log 2>&1

pip install --upgrade pip
pip install --upgrade setuptools
pip install cqlsh

# Install Docker engine
touch /var/log/tf/docker_install.log ; sudo chmod go+rw /var/log/tf/docker_install.log

curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  apt-key add -  >> /var/log/tf/docker_install.log 2>&1

add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"  >> /var/log/tf/docker_install.log 2>&1
sudo apt-get update  >> /var/log/tf/docker_install.log 2>&1
apt-cache policy docker-ce >> /var/log/tf/docker_install.log 2>&1

apt-get install -y docker-ce >> /var/log/tf/docker_install.log 2>&1

echo "INFO: `date`: Docker package installation complete.."  >> /var/log/tf/docker_install.log

# create vnet and pull image
echo "INFO: creating network vnet"
docker network create vnet >> /var/log/tf/docker_install.log
IMAGE_NAME="oleggorj/cassandra:3.11.0-alpine"

echo "INFO: pulling and executing $IMAGE_NAME "
#docker run --net vnet --name cassandra -d oleggorj/cassandra:3.11.0-alpine  >> /var/log/tf/docker_install.log
mkdir /home/cassandra ; chmod go+rw /home/cassandra
docker run --name cassandra -p 7000:7000 -p 7001:7001 -p 7199:7199 -p 9042:9042 -p 9160:9160 -v /home/cassandra:/usr/local/apache-cassandra-3.11.0/data -d oleggorj/cassandra:3.11.0-alpine >> /var/log/tf/docker_install.log

echo "INFO: `date`: Docker Image pull/installation complete.."  >> /var/log/tf/docker_install.log


# Get the github.com SSH information so we don't get prompted when pulling code
# ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
# command
cp /root/.ssh/known_hosts /home/${TERRAFORM_user}/.ssh/known_hosts
chown ${TERRAFORM_user}:${TERRAFORM_user} /home/${TERRAFORM_user}/.ssh/known_hosts
