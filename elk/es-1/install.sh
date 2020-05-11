#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install wget apt-transport-https default-jre gnupg2 ca-certificates lsb-release -y
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
wget -qO - https://nginx.org/keys/nginx_signing.key | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
echo "deb http://nginx.org/packages/debian `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
sudo apt-get update
sudo apt-get install kibana elasticsearch logstash nginx

sudo cp elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
sudo cp jvm.options /etc/elasticsearch/jvm.options
sudo cp logstash.yml /etc/logstash/logstash.yml
sudo cp pipeline.conf /etc/logstash/conf.d/
sudo cp kibana.yml /etc/kibana/kibana.yml
sudo cp kibana-proxy.conf /etc/nginx/conf.d/kibana-proxy.conf
sudo cp nginx.conf /etc/nginx/nginx.conf
