#!/usr/bin/env bash
set -euo pipefail
image=${1:?image required}
name="anki-smoke-${RANDOM}"
cleanup() {
  docker rm -f -v "$name" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run -d --name "$name" --network none \
  -e SYNC_USER1=ci:temporary-smoke-test \
  --tmpfs /anki_data:rw "$image" >/dev/null

for attempt in {1..60}; do
  if docker exec "$name" anki-sync-server --healthcheck >/dev/null 2>&1; then
    echo 'Image starts and passes its Anki healthcheck'
    exit 0
  fi
  if [[ $(docker inspect -f '{{.State.Running}}' "$name") != true ]]; then
    docker logs "$name"
    exit 1
  fi
  sleep 2
done
docker logs "$name"
echo 'Startup healthcheck timed out' >&2
exit 1
