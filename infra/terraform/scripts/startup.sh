#!/bin/bash
apt-get update
apt-get install -y docker.io
docker run -d -p 3000:3000 --name ${var.name} ${var.docker_image}