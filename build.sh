#!/bin/sh

docker build -t polysign/rancheroo:latest .
docker push polysign/rancheroo:latest
