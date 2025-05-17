#!/bin/bash
apt-get update
apt-get install -y docker.io
systemctl start docker



#!/bin/bash

apt-get update
apt-get install -y docker.io
systemctl start docker

# Pull app image from GCR
docker pull ${DOCKER_IMAGE}

# Run DB migrations using TypeORM
docker run --rm \
  -e DB_HOST="${DB_HOST}" \
  -e DB_USERNAME="${DB_USERNAME}" \
  -e DB_NAME="${DB_NAME}" \
  -e DB_PORT="${DB_PORT}" \
  -e DB_PASSWORD="${DB_PASSWORD}" \
  ${DOCKER_IMAGE} \
  node dist/main.js migration:run

# Start the app container
docker run -d \
  --name ${CONTAINER_NAME} \
  -e DB_HOST="${DB_HOST}" \
  -e DB_USERNAME="${DB_USERNAME}" \
  -e DB_NAME="${DB_NAME}" \
  -e DB_PORT="${DB_PORT}" \
  -e DB_PASSWORD="${DB_PASSWORD}" \
  -e REDIS_HOST="${REDIS_HOST}" \
  -e REDIS_PORT="${REDIS_PORT}" \
  -e TTL="${TTL}" \
  -e REDIS_PORT="${REDIS_PORT}" \
  -p 3000:3000 \
  ${DOCKER_IMAGE}