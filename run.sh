#!/bin/bash
# repo: https://github.com/doctorlai/simple-steem-docker
# by Steem Witness: @justyy
# Thanks to Steem Witness: @ety001 on his post: https://steemit.com/witness/@ety001/how-to-deploy-a-steem-witness-node-by-docker

DOCKER_NAME="steem"
DOCKER_IMAGE="ety001/steem-full-mira"

## 2001 is seed port
## 8091 is API pord - optional, remove if you don't expose API
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

