#!/bin/bash
# repo: https://github.com/doctorlai/simple-steem-docker
# Steem Witness: @justyy
# Acknowledgement: https://steemit.com/witness/@ety001/how-to-deploy-a-steem-witness-node-by-docker
set -e

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

print() {
    echo "========================================="
    echo " Docker Configuration"
    echo "========================================="
    echo "DOCKER_NAME          = $DOCKER_NAME"
    echo "DOCKER_IMAGE         = $DOCKER_IMAGE"
    echo "LOCAL_STEEM_LOCATION = $LOCAL_STEEM_LOCATION"
    [ ! -d "$LOCAL_STEEM_LOCATION" ] && echo "Warning: $LOCAL_STEEM_LOCATION does not exist"
    echo "ULIMIT_NUMBER        = $ULIMIT_NUMBER"
    echo "SEED_PORT            = $SEED_PORT"
    echo "API_PORT             = $API_PORT"
    echo "DOCKER_ARGS          = $DOCKER_ARGS"    
    echo "========================================="
}

container_exists() {
    docker ps -a --format '{{.Names}}' | grep -qw "$1"
}

container_running() {
    docker ps --format '{{.Names}}' | grep -qw "$1"
}

status() {
    if ! container_exists "$DOCKER_NAME"; then
        echo "Container '$DOCKER_NAME' does not exist."
        return 1
    fi

    container_id=$(docker ps -a -q -f name="^$DOCKER_NAME$")
    running=$(docker inspect -f '{{.State.Running}}' "$container_id")
    echo "========================================="
    echo " Docker Container Status"
    echo "========================================="
    echo "Container Name : $DOCKER_NAME"
    echo "Container ID   : $container_id"
    echo "Image          : $(docker inspect -f '{{.Config.Image}}' "$container_id")"
    echo "Running        : $running"
    echo "Ports          : $(docker port "$container_id")"
    echo "Mounts         :"
    docker inspect -f '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' "$container_id"
    echo "Ulimit nofile  : $(docker inspect -f '{{index .HostConfig.Ulimits 0 "Hard"}}' "$container_id" 2>/dev/null || echo "N/A")"
    echo "Restart Policy : $(docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' "$container_id")"
    echo "Memory/CPU     :"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" "$container_id"
    echo "========================================="
    return 0
}

start() {
    if container_running "$DOCKER_NAME"; then
        echo "Container '$DOCKER_NAME' is already running."
        return 1
    fi

    # Container exists but stopped → remove it
    if container_exists "$DOCKER_NAME"; then
        echo "Removing existing/stopped container '$DOCKER_NAME'."
        docker rm "$DOCKER_NAME"
    fi
    ## check directory
    if [ ! -d "$LOCAL_STEEM_LOCATION" ]; then
        echo "The local steem data directory '$LOCAL_STEEM_LOCATION' does not exist."
        echo "Please create it and ensure proper permissions."
        return 1
    fi
    docker run -itd \
        --name "$DOCKER_NAME" \
        $DOCKER_ARGS \
        --ulimit nofile="$ULIMIT_NUMBER" \
        -v "$LOCAL_STEEM_LOCATION":/steem \
        "$DOCKER_IMAGE" \
        steemd --data-dir=/steem
}

test() {
    docker run -it --rm \
        $DOCKER_ARGS \
        --ulimit nofile="$ULIMIT_NUMBER" \
        -v "$LOCAL_STEEM_LOCATION":/steem \
        "$DOCKER_IMAGE" \
        /bin/bash
}

stop() {
    if ! container_exists "$DOCKER_NAME"; then
        echo "Container '$DOCKER_NAME' does not exist."
        return 1
    fi
    echo "Stopping container: $DOCKER_NAME"
    docker stop -t 600 "$DOCKER_NAME" 2>/dev/null
    docker rm "$DOCKER_NAME" 2>/dev/null
    return 0
}

kill() {
    if ! container_exists "$DOCKER_NAME"; then
        echo "Container '$DOCKER_NAME' does not exist."
        return 1
    fi
    echo "Force killing container: $DOCKER_NAME"
    docker kill "$DOCKER_NAME" 2>/dev/null
    docker rm -f "$DOCKER_NAME" 2>/dev/null
    return 0
}

debug() {
    if ! container_running "$DOCKER_NAME"; then
        echo "Container '$DOCKER_NAME' is not running. Please start it first."
        return 1
    fi
    docker exec -it "$DOCKER_NAME" /bin/bash
}

restart() {
    stop || true
    start
}

logs() {
    if ! container_exists "$DOCKER_NAME"; then
        echo "Container '$DOCKER_NAME' does not exist."
        return 1
    fi
    tail_count="${1:-100}"
    if [ "$tail_count" = "all" ]; then
        docker logs -f "$DOCKER_NAME"
    else
        docker logs -f --tail "$tail_count" "$DOCKER_NAME"
    fi
    return 0
}

# ==========================
# Main
# ==========================

case "$1" in
    start)      start ;;
    stop)       stop ;;
    kill)       kill ;;
    restart)    restart ;;
    logs)       logs "$2" ;;
    debug)      debug ;;
    test)       test ;; 
    print)      print ;;
    status)     status ;;
    *)
        echo "Usage: $0 {start|stop|kill|restart|logs [num=100|all]|debug|print|status|test}"
        exit 1
        ;;
esac
