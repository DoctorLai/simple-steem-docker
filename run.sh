#!/bin/bash
# repo: https://github.com/doctorlai/simple-steem-docker
# by Steem Witness: @justyy
# Thanks to Steem Witness: @ety001 on his post: https://steemit.com/witness/@ety001/how-to-deploy-a-steem-witness-node-by-docker

## Usage
### export DOCKER_NAME="steem"
### export DOCKER_IMAGE="steem:latest"
### ./run.sh [start | stop | restart | logs]

# Default values
DEFAULT_DOCKER_NAME="steem"
DEFAULT_DOCKER_IMAGE="steem:latest"
DEFAULT_LOCAL_STEEM_LOCATION="/root/steem-docker/data/witness_node_data_dir"

# Check if the environment variables are set, if not use the default values
DOCKER_NAME=${DOCKER_NAME:-$DEFAULT_DOCKER_NAME}
DOCKER_IMAGE=${DOCKER_IMAGE:-$DEFAULT_DOCKER_IMAGE}
LOCAL_STEEM_LOCATION=${LOCAL_STEEM_LOCATION:-$DEFAULT_LOCAL_STEEM_LOCATION}

## 2001 is seed port
## 8091 is API pord - optional, remove if you don't expose API
start() {
    docker run -itd \
        --name $DOCKER_NAME \
        -p 2001:2001 \
        -p 8091:8091 \
		--ulimit nofile=999999 \
        -v $LOCAL_STEEM_LOCATION:/steem \
        $DOCKER_IMAGE \
        /usr/local/steemd/bin/steemd --data-dir=/steem
}

stop() {
    docker network disconnect bridge $DOCKER_NAME
    docker stop -t 600 $DOCKER_NAME
    docker rm $DOCKER_NAME
}

restart() {
    stop
    start
}

logs() {
    docker logs -f --tail 100 $DOCKER_NAME
}

# Main script: Check the parameter passed to the script
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    logs)
        logs
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs}"
        exit 1
        ;;
esac
