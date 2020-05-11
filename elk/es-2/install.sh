#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install wget default-jre -y
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update
sudo apt-get install elasticsearch

sudo mkdir /mnt/es-data
sudo mount -o discard,defaults /dev/sdb /mnt/es-data
sudo chmod a+w /mnt/es-data
sudo chown -R elasticsearch:elasticsearch /mnt/es-data

sudo cp elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
sudo cp jvm.options /etc/elasticsearch/jvm.options
