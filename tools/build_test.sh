#!/usr/bin/env bash

# This script builds the Jekyll site and then runs htmlproofer checks
# using Docker Compose.

# Exit immediately if a command exits with a non-zero status.
set -e

# Define variables for better readability
SERVICE_NAME="jekyll"
JEKYLL_DEST_DIR="_site"
HTMLPROOFER_OPTS=(
    "--disable-external"
    "--no-enforce-https"
    "--allow_missing_href"
    "--ignore-urls" "/^http://127.0.0.1/,/^http://0.0.0.0/,/^http://localhost/"
)

echo "Starting Jekyll build within the Docker container..."

# Execute Jekyll build command
docker compose exec -it "${SERVICE_NAME}" bash -c \
    "JEKYLL_ENV=\"production\" bundle exec jekyll build -d \"${JEKYLL_DEST_DIR}\""

echo "Jekyll build completed. Running HTML Proofer checks..."

# Execute HTML Proofer command
docker compose exec -it "${SERVICE_NAME}" bash -c \
    "bundle exec htmlproofer ${JEKYLL_DEST_DIR} ${HTMLPROOFER_OPTS[*]}"

echo "HTML Proofer checks completed."
echo "Site build and test process finished successfully."