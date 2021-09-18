#!/bin/sh

# Builds a docker container if needed (with its dependencies for interactive/headless execution)
# and executes tests via script ./runCypressTests.sh within a corresponding container
#
# Headless usage example:
#   ./runCypressTestsContainer.sh test all local
# Interactive usage example using a VNC server:
#   ./runCypressTestContainer.sh start local
# In this case you need to connect to the VNC server after it started using either
#   a) a native VNC client: `vncviewer localhost:5901` or
#   b) by browsing the web VNC client at http://localhost:6901

set -e

PRJDIR="$(cd "$(dirname "$0")"/../.. && pwd)"
PRJNAME="${PWD##*/}"

runInContainer() {
  # TODO: use unprivileged user (-u) within container instead (requires to fix some permissions/user issues within the container first)
  docker build --force-rm -t cypress -f Cypress_Dockerfile "$PRJDIR"
  docker run -it --rm \
    -v "$PRJDIR/cypress:/e2e/cypress" \
    -v "$PRJDIR/cypress.json:/e2e/cypress.json" \
    -v "$PRJDIR/cypress/scripts:/e2e/scripts" \
    --shm-size 2g \
    -p 5901:5901 \
    -p 6901:6901 \
    -e VNC_ENABLED=$VNC_ENABLED \
    --network="host" \
    cypress \
    /e2e/cypress/scripts/runCypressTests.sh "$@"
}

case "$1" in
  start)
    # Runs all tests using VNC server within container
    # Usage: $0 start; ...; vncviewer localhost:5901
    VNC_ENABLED=1
    shift
    runInContainer start "$@"
  ;;
  test|test_electron|test_chrome|test_firefox|test_edge)
    # Runs all tests headless
    runInContainer "$@"
  ;;
  *)
    echo "Invalid input: $1" >&2
    echo "Usage: $0 start|test|test_electron|test_chrome|test_firefox|test_edge" >&2
    exit 1
  ;;
esac
