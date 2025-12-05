#!/bin/bash
# repo: https://github.com/doctorlai/simple-steem-docker
# Steem Witness: @justyy
# Acknowledgement: https://steemit.com/witness/@ety001/how-to-deploy-a-steem-witness-node-by-docker

# ==========================
# Default values
# ==========================
DEFAULT_DOCKER_NAME="steem"
DEFAULT_DOCKER_IMAGE="steem:latest"
DEFAULT_LOCAL_STEEM_LOCATION="/root/steem-docker/data/witness_node_data_dir"
ULIMIT_NUMBER=999999

# Load environment overrides
DOCKER_NAME="${DOCKER_NAME:-$DEFAULT_DOCKER_NAME}"
DOCKER_IMAGE="${DOCKER_IMAGE:-$DEFAULT_DOCKER_IMAGE}"
LOCAL_STEEM_LOCATION="${LOCAL_STEEM_LOCATION:-$DEFAULT_LOCAL_STEEM_LOCATION}"

# Ports
SEED_PORT="-p 2001:2001"
API_PORT="-p 8091:8091"  # remove if not exposing API

DOCKER_ARGS="$SEED_PORT $API_PORT"

# ==========================
# Functions
# ==========================

start() {
    docker run -itd \
        --name "$DOCKER_NAME" \
        $DOCKER_ARGS \
        --ulimit nofile="$ULIMIT_NUMBER" \
        -v "$LOCAL_STEEM_LOCATION":/steem \
        "$DOCKER_IMAGE" \
        steemd --data-dir=/steem
}

debug() {
    docker run -it \
        --name "$DOCKER_NAME" \
        $DOCKER_ARGS \
        --ulimit nofile="$ULIMIT_NUMBER" \
        -v "$LOCAL_STEEM_LOCATION":/steem \
        "$DOCKER_IMAGE" \
        /bin/bash
}

stop() {
    docker stop -t 600 "$DOCKER_NAME" 2>/dev/null
    docker rm "$DOCKER_NAME" 2>/dev/null
}

restart() {
    stop
    start
}

logs() {
    tail_count="${1:-100}"
    docker logs -f --tail "$tail_count" "$DOCKER_NAME"
}

# ==========================
# Main
# ==========================

case "$1" in
    start)      start ;;
    stop)       stop ;;
    restart)    restart ;;
    logs)       logs "$2" ;;
    debug)      debug ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs [num=100]|debug}"
        exit 1
        ;;
esac
