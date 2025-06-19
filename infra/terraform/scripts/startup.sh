#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  apt-get update
  apt-get install -y docker.io
  systemctl enable --now docker
fi

APP_DIR="/opt/app"
ENV_FILE="$APP_DIR/.env"

mkdir -p "$APP_DIR"

cat > "$ENV_FILE" <<EOF
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=${DB_HOST}
DB_NAME=${DB_NAME}
DB_PORT=${DB_PORT}
TTL=${TTL}
PUBSUB_TOPIC=${PUBSUB_TOPIC}
REDIS_HOST=${REDIS_HOST}
REDIS_PORT=${REDIS_PORT}
THRESHOLD=${THRESHOLD}
GOOGLE_PROJECT_ID=${GOOGLE_PROJECT_ID}
EOF

cd $APP_DIR

export $(cat $ENV_FILE | xargs)

sudo gcloud auth configure-docker us-central1-docker.pkg.dev --quiet

echo "running datadog container"
sudo docker run -d --name dd-agent \
-e DD_API_KEY="${DD_API_KEY}"\
-e DD_SITE="${DD_SITE}" \
-e DD_DOGSTATSD_NON_LOCAL_TRAFFIC=true \
-e DD_ENV="${DD_ENV_NAME}" \
-v /var/run/docker.sock:/var/run/docker.sock:ro \
-v /proc/:/host/proc/:ro \
-v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
-v /var/lib/docker/containers:/var/lib/docker/containers:ro \
gcr.io/datadoghq/agent:7

echo "Pulling image ${DOCKER_IMAGE}..."
sudo docker pull "${DOCKER_IMAGE}"


echo "Running database migrations..."

sudo docker run --rm \
  --env-file .env \
  -e GOOGLE_PROJECT_ID="${GOOGLE_PROJECT_ID}" \
  -p 3000:3000 \
  "${DOCKER_IMAGE}" \
  npm run migration:run

echo "Starting container ${CONTAINER_NAME}..."

sudo docker run --rm \
  --env-file .env \
  -e GOOGLE_PROJECT_ID="${GOOGLE_PROJECT_ID}" \
  -p 3000:3000 \
  "${DOCKER_IMAGE}" \
  npm run start:prod


echo "Application deployed and running as container ${CONTAINER_NAME}."
