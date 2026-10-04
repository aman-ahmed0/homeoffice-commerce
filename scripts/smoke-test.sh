#!/usr/bin/env bash
# Start a built image and check that it really serves requests.
# Usage: bash scripts/smoke-test.sh <backend|frontend> <image>
set -euo pipefail

component="$1"
image="$2"
network="smoke-${component}"

cleanup() {
  status=$?
  if [ "${status}" -ne 0 ]; then
    echo "Smoke test failed. Last container logs:"
    docker logs "smoke-${component}" 2>&1 | tail -n 50 || true
  fi
  docker rm --force "smoke-${component}" smoke-db >/dev/null 2>&1 || true
  docker network rm "${network}" >/dev/null 2>&1 || true
  exit "${status}"
}
trap cleanup EXIT

wait_for() {
  for attempt in $(seq 1 30); do
    if curl --fail --silent --output /dev/null "$1"; then
      return 0
    fi
    sleep 2
  done
  echo "No healthy response from $1 after 60 seconds"
  return 1
}

docker network create "${network}" >/dev/null

case "${component}" in
  backend)
    # Throwaway database with the same major version as the cluster.
    docker run --detach --name smoke-db --network "${network}" \
      --env POSTGRES_USER=smoke --env POSTGRES_PASSWORD=smoke --env POSTGRES_DB=smoke \
      postgres:15 >/dev/null
    docker run --detach --name smoke-backend --network "${network}" \
      --publish 127.0.0.1:5000:5000 \
      --env POSTGRES_USER=smoke --env POSTGRES_PASSWORD=smoke --env POSTGRES_DB=smoke \
      --env DB_HOST=smoke-db --env DB_PORT=5432 \
      "${image}" >/dev/null
    wait_for http://127.0.0.1:5000/healthz
    products=$(curl --fail --silent --show-error http://127.0.0.1:5000/api/products)
    count=$(python3 -c 'import json, sys; print(len(json.loads(sys.argv[1])))' "${products}")
    echo "Backend healthy, products returned: ${count}"
    [ "${count}" -gt 0 ]
    ;;
  frontend)
    docker run --detach --name smoke-frontend --network "${network}" \
      --publish 127.0.0.1:3000:3000 \
      "${image}" >/dev/null
    wait_for http://127.0.0.1:3000/
    page=$(curl --fail --silent --show-error http://127.0.0.1:3000/)
    grep --quiet "HomeOffice Hub" <<< "${page}"
    echo "Frontend healthy, homepage served"
    ;;
  *)
    echo "Unknown component: ${component}"
    exit 2
    ;;
esac
