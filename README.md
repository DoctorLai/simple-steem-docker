# Docker Steem Witness Node Utility
This utility script helps manage a Steem witness node using Docker. You can start, stop, restart, and view logs of the witness node container with simple commands.

## Requirements
- Docker installed and running
- A Steem witness node Docker image (`ety001/steem-full-mira` in this example)

## Environment Variables
The following environment variables can be used to customize the behavior of the script:

### DOCKER_NAME
Description: The name of the Docker container that will run the Steem witness node.
Default: steem
Example:
```bash
export DOCKER_NAME="my_steem_container"
```

### DOCKER_IMAGE
Description: The Docker image that will be used to run the Steem witness node.
Default: steem:latest
Example:
```bash
export DOCKER_IMAGE="my_custom_steem_image:latest"
```

### LOCAL_STEEM_LOCATION
Description: The local directory where Steem data will be stored. This directory will be mounted to the Docker container.
Default: /root/steem-docker/data/witness_node_data_dir
Example:
```bash
export LOCAL_STEEM_LOCATION="/mnt/my_steem_data"
```

## Usage
To customize the behavior of the script, set any of the environment variables listed above before running the script. If you do not set any of the variables, the script will use the following default values:

- DOCKER_NAME: steem
- DOCKER_IMAGE: steem:latest
- LOCAL_STEEM_LOCATION: /root/steem-docker/data/witness_node_data_dir

### Example with Custom Environment Variables
```bash
export DOCKER_NAME="my_steem_node"
export DOCKER_IMAGE="custom_steem_image:latest"
export LOCAL_STEEM_LOCATION="/mnt/custom_steem_data"
```

If you do not set any environment variables, the script will run with the default values:

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

This command will stop the Steem witness node, disconnect it from the Docker network (if connected), and remove the Docker container.

## Restart the Steem Witness Node
```bash
./run.sh restart
```

This command will stop and then restart the Steem witness node. This is the same as calling:

```bash
./run.sh stop
./run.sh start
```

## View Logs of the Steem Witness Node
```bash
./run.sh logs
```

This command will display the logs of the running Steem witness node Docker container, tailing the last 100 lines and following new log entries.
