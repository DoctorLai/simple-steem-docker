# Docker Steem Witness Node Utility
This utility script helps manage a Steem witness node using Docker. You can start, stop, restart, and view logs of the witness node container with simple commands.

## Requirements
- Docker installed and running
- A Steem witness node Docker image (ety001/steem-full-mira in this example)

## Usage
You can use this script to manage the Docker container running the Steem witness node. The script supports the following operations:

### Start the Steem Witness Node
```bash
./run.sh start
```

This command will start the Steem witness node in a Docker container, mapping the following ports:

- 2001:2001 – Used by the Steem witness node (seed)
- 8091:8091 – HTTP RPC port for the witness node

The Steem data will be mounted to /data/steem/data on the host.

## Stop the Steem Witness Node
```bash
./run.sh stop
```

This command will stop the Steem witness node, disconnect it from the lnmp Docker network (if connected), and remove the Docker container.

## Restart the Steem Witness Node
```bash
./run.sh restart
```

This command will stop and then restart the Steem witness node.

## View Logs of the Steem Witness Node
```bash
./run.sh logs
```

This command will display the logs of the running Steem witness node Docker container, tailing the last 100 lines and following new log entries.
