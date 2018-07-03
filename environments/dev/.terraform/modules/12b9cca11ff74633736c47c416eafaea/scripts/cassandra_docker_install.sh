#!/bin/bash -v

sudo su -

mkdir /var/log/tf/ ; chown -R ubuntu:ubuntu /var/log/tf/; chmod -R go+rw /var/log/tf


# create vnet and pull image
echo "INFO: creating network vnet"
docker network create vnet >> /var/log/tf/docker_install.log
IMAGE_NAME="oleggorj/cassandra:3.11.0-alpine"

echo "INFO: pulling and executing $IMAGE_NAME "
#docker run --net vnet --name cassandra -d oleggorj/cassandra:3.11.0-alpine  >> /var/log/tf/docker_install.log
mkdir /home/cassandra ; chmod go+rw /home/cassandra
docker run --name cassandra -p 7000:7000 -p 7001:7001 -p 7199:7199 -p 9042:9042 -p 9160:9160 -v /home/cassandra:/usr/local/apache-cassandra-3.11.0/data -d oleggorj/cassandra:3.11.0-alpine >> /var/log/tf/docker_install.log

echo "INFO: `date`: Docker Image pull/installation complete.."  >> /var/log/tf/docker_install.log
