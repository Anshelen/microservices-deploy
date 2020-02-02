#!/bin/bash

helm package msvc-chart/ -d docs/ > /dev/null 2>&1
helm repo index docs/ --url https://anshelen.github.io/microservices-deploy/
