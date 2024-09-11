#!/bin/bash
# https://steemit.com/witness/@ety001/how-to-deploy-a-steem-witness-node-by-docker

DOCKER_NAME="steem"
DOCKER_IMAGE="ety001/steem-full-mira"

start() {
    docker run -itd \
        --name $DOCKER_NAME \
        -p 2001:2001 \
        -p 8091:8091 \
        -v /data/steem/data:/steem \
        $DOCKER_IMAGE \
        steemd --data-dir=/steem
}

stop() {
    docker network disconnect lnmp $DOCKER_NAME
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

