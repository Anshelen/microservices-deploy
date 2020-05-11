#!/usr/bin/env bash

sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
sudo systemctl enable logstash
sudo systemctl start logstash
sudo systemctl enable kibana
sudo systemctl start kibana
sudo systemctl enable nginx
sudo systemctl start nginx
