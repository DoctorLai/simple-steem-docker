#!/bin/bash
# repo: https://github.com/doctorlai/simple-steem-docker
# Steem Witness: @justyy
# Acknowledgement: https://steemit.com/witness/@ety001/how-to-deploy-a-steem-witness-node-by-docker
set -e


#### Example of docker-compose.yaml if you are using Jussi and want to connect to the steemd container via the internal Docker network:
## you need to join to the same Docker network (steem-net) and use the same network alias (steemd) as defined in this script
## to verify, both should show steem-net:
### docker inspect jussi-jussi-1 --format '{{json .NetworkSettings.Networks}}' | jq
### docker inspect steem --format '{{json .NetworkSettings.Networks}}' | jq

## in jussi config, use "http://steemd:8091" as the upstream URL to connect to the steemd container via Docker network
# services:
#   jussi:
#     restart: "always"
#     image: "steemit/jussi:latest"
#     ports:
#       - "8080:8080"
#     environment:
#       JUSSI_UPSTREAM_CONFIG_FILE: /app/config.json
#       JUSSI_REDIS_URL: redis://redis1:6379
#     volumes:
#       - ./config.json:/app/config.json
#     networks:
#       - steem-net

#   redis1:
#     restart: "always"
#     image: "redis:latest"
#     volumes:
#       - ./redis1:/data
#     networks:
#       - steem-net

# networks:
#   steem-net:
#     external: true


#### Manual steps to connect Jussi to the steemd container if you are not using docker-compose:
## 1. Connect existing steem container: docker network connect --alias steemd steem-net steem
## 2. Connect Jussi container (if not already): docker network connect steem-net jussi-jussi-1
## 3. Test: docker exec -it jussi-jussi-1 curl -s \
#   -H "Content-Type: application/json" \
#   --data '{"jsonrpc":"2.0","method":"condenser_api.get_block","params":[1],"id":1}' \
#   http://steemd:8091 | jq

# ==========================
# Default values
# ==========================
DEFAULT_DOCKER_NAME="steem"
DEFAULT_DOCKER_IMAGE="steem:latest"
DEFAULT_LOCAL_STEEM_LOCATION="/root/steem-docker/data/witness_node_data_dir"
ULIMIT_NUMBER=999999
DEFAULT_STEEM_WS_PORT=8090
## no, always, unless-stopped, on-failure <max-retry-count>
DEFAULT_RESTART_POLICY="unless-stopped"
DEFAULT_DOCKER_NETWORK="steem-net"
DEFAULT_DOCKER_ALIAS="steemd"

# Load environment overrides
DOCKER_NAME="${DOCKER_NAME:-$DEFAULT_DOCKER_NAME}"
DOCKER_IMAGE="${DOCKER_IMAGE:-$DEFAULT_DOCKER_IMAGE}"
LOCAL_STEEM_LOCATION="${LOCAL_STEEM_LOCATION:-$DEFAULT_LOCAL_STEEM_LOCATION}"
STEEM_WS_PORT="${STEEM_WS_PORT:-$DEFAULT_STEEM_WS_PORT}"
RESTART_POLICY="${RESTART_POLICY:-$DEFAULT_RESTART_POLICY}"
DOCKER_NETWORK="${DOCKER_NETWORK:-$DEFAULT_DOCKER_NETWORK}"
DOCKER_ALIAS="${DOCKER_ALIAS:-$DEFAULT_DOCKER_ALIAS}"

# Ports
SEED_PORT="-p 2001:2001"
API_PORT="-p 8091:8091"  # remove if not exposing API
DOCKER_ARGS="$SEED_PORT $API_PORT"

# ==========================
# Functions
# ==========================

ensure_network() {
    if ! docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1; then
        echo "Creating Docker network: $DOCKER_NETWORK"
        docker network create "$DOCKER_NETWORK"
    else
        echo "Docker network '$DOCKER_NETWORK' already exists."
    fi
}

validate_restart_policy() {
    case "$RESTART_POLICY" in
        no|always|unless-stopped|on-failure* ) ;;
        *)
            echo "Invalid RESTART_POLICY: $RESTART_POLICY"
            echo "Valid values: no | always | unless-stopped | on-failure[:N]"
            exit 1
            ;;
    esac
}

print_config() {
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
    echo "STEEM_WS_PORT        = $STEEM_WS_PORT"
    echo "RESTART_POLICY       = $RESTART_POLICY"
    echo "DOCKER_NETWORK       = $DOCKER_NETWORK"
    echo "DOCKER_ALIAS         = $DOCKER_ALIAS"
    echo "========================================="
}

install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker not found. Installing Docker..."
        curl -fsSL https://get.docker.com -o ~/get-docker.sh
        sh ~/get-docker.sh
        rm ~/get-docker.sh
        echo "Docker installed successfully."
    else
        echo "Docker is already installed."
    fi
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
    echo "Networks       : $(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' "$container_id")"
    echo "========================================="
    return 0
}

start() {
    validate_restart_policy
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
    ensure_network
    docker run -itd \
        --name "$DOCKER_NAME" \
        --restart "$RESTART_POLICY" \
        --network "$DOCKER_NETWORK" \
        --network-alias "$DOCKER_ALIAS" \
        $DOCKER_ARGS \
        --ulimit nofile=$ULIMIT_NUMBER:$ULIMIT_NUMBER \
        -v "$LOCAL_STEEM_LOCATION":/steem \
        "$DOCKER_IMAGE" \
        steemd --data-dir=/steem
}

test() {
    ensure_network
    docker run -it --rm \
        --network "$DOCKER_NETWORK" \
        --network-alias "$DOCKER_ALIAS-test" \
        $DOCKER_ARGS \
        --ulimit nofile=$ULIMIT_NUMBER:$ULIMIT_NUMBER \
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

wallet() {
    if ! container_running "$DOCKER_NAME"; then
        echo "Container '$DOCKER_NAME' is not running. Please start it first."
        return 1
    fi
    docker exec -it "$DOCKER_NAME" cli_wallet -s ws://127.0.0.1:$STEEM_WS_PORT
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
    tail_args=""
    disable_follow="${2:-false}"
    if [ "$tail_count" != "all" ]; then
        tail_args="-n $tail_count"
    fi
    if [ "$disable_follow" != "true" ]; then
        tail_args="$tail_args -f"
    fi
    docker logs $tail_args "$DOCKER_NAME"
    return 0
}

container_logs() {
    tail_count="${1:-100}"
    tail_args=""
    if [ "$tail_count" != "all" ]; then
        tail_args="-n $tail_count"
    fi
    disable_follow="${2:-false}"
    if [ "$disable_follow" != "true" ]; then
        tail_args="$tail_args -f"
    fi
    tail $tail_args /var/lib/docker/containers/*/*.log
}

# ==========================
# Main
# ==========================

case "$1" in
    start)      start ;;
    stop)       stop ;;
    kill)       kill ;;
    restart)    restart ;;
    logs)       logs "$2" "$3" ;;
    container_logs) container_logs "$2" "$3" ;;
    debug)      debug ;;
    test)       test ;; 
    print)      print_config ;;
    status)     status ;;
    install_docker) install_docker ;;
    wallet)     wallet ;;
    *)
        echo "Usage: $0 {start|stop|kill|restart|logs [num=100|all]|debug|print|status|test|install_docker|wallet}"
        echo "  start            - Start the Steem Docker container"
        echo "  stop             - Stop the Steem Docker container gracefully"
        echo "  kill             - Force kill the Steem Docker container"
        echo "  restart          - Restart the Steem Docker container"
        echo "  logs [num|all] [<disable_follow>]   - View the Steem Docker container logs (default last 100 lines, or 'all' for full logs), optionally disable follow"
        echo "  container_logs [num|all] [<disable_follow>] - View raw Docker container logs (default last 100 lines, or 'all' for full logs), optionally disable follow"
        echo "  debug           - Access the Steem Docker container shell for debugging"
        echo "  print            - Print the current configuration"
        echo "  status           - Show the status of the Steem Docker container"
        echo "  test             - Run a temporary Steem Docker container for testing"
        echo "  install_docker  - Install Docker if not already installed"
        echo "  wallet          - Access the Steem wallet CLI inside the running container"
        exit 1
        ;;
esac
