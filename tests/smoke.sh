#!/usr/bin/env bash
set -e

BASE_URL="${1:-http://localhost:3000}" 
echo "Running smoke tests against $BASE_URL"

# list posts
curl -fsS "$BASE_URL/posts" | jq -C '.' >/dev/null && echo "GET /posts: OK"

# create post (if API supports POST)
curl -fsS -X POST "$BASE_URL/posts" -H 'Content-Type: application/json' \
  -d '{"title":"smoke","body":"smoke"}' -o /dev/null && echo "POST /posts: OK"

echo "Smoke tests passed."
