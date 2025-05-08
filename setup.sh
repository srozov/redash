#!/usr/bin/env sh

set -eu

REDASH_BASE_PATH="$(pwd)"
ENV_FILE="$REDASH_BASE_PATH/.env"
POSTGRES_DATA_DIR="$REDASH_BASE_PATH/postgres-data"

# Create necessary directories
if [ ! -d "$POSTGRES_DATA_DIR" ]; then
  mkdir -p "$POSTGRES_DATA_DIR"
  echo "Created $POSTGRES_DATA_DIR"
fi

# Generate .env file if it doesn't exist
if [ ! -f "$ENV_FILE" ]; then
  echo "Generating .env file"
  COOKIE_SECRET=$(openssl rand -hex 16)
  SECRET_KEY=$(openssl rand -hex 16)
  PG_PASSWORD=$(openssl rand -hex 16)
  cat <<EOF >"$ENV_FILE"
PYTHONUNBUFFERED=0
REDASH_LOG_LEVEL=INFO
REDASH_REDIS_URL=redis://redis:6379/0
REDASH_COOKIE_SECRET=$COOKIE_SECRET
REDASH_SECRET_KEY=$SECRET_KEY
POSTGRES_PASSWORD=$PG_PASSWORD
REDASH_DATABASE_URL=postgresql://postgres:${PG_PASSWORD}@postgres/postgres
REDASH_ENFORCE_CSRF=true
REDASH_GUNICORN_TIMEOUT=60
EOF
  echo ".env file created"
else
  echo ".env file already exists, skipping"
fi

# Run database migrations
echo "Running database migrations..."
docker compose run --rm server create_db

# Start Redash services
echo "Starting Redash services..."
docker compose up -d

echo
echo "Redash is ready at http://localhost:5000"
echo
