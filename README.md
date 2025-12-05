# Docker Steem Witness Node Utility

This utility script helps manage a Steem witness node using Docker. You can start, stop, restart, force kill, debug, print configuration, check status, and view logs of the witness node container with simple commands.

---

## Requirements

- Docker installed and running  
- A Steem witness node Docker image (For example: `justyy/steem:ubuntu24.04`). See all images at [justyy/steem](https://hub.docker.com/r/justyy/steem)

---

## Environment Variables

The following environment variables can be used to customize the behavior of the script. The script respects any environment variable you export before running it. If a variable is not set, the default value will be used.

---

### `DOCKER_NAME`

- **Description:** The name of the Docker container that will run the Steem witness node.  
- **Default:** `steem`  
- **Example:**

<code>export DOCKER_NAME="steem"</code>

---

### `DOCKER_IMAGE`

- **Description:** The Docker image that will be used to run the Steem witness node.  
- **Default:** `steem:latest`  
- **Example:**

<code>export DOCKER_IMAGE="steem:latest"</code>

You can pull prebuilt images from [justyy/steem](https://hub.docker.com/r/justyy/steem/tags), for example:

<code>docker pull justyy/steem:ubuntu24.04</code>

---

### `LOCAL_STEEM_LOCATION`

- **Description:** The local directory where Steem data will be stored. This directory will be mounted to the Docker container i.e. `/steem`.
- **Default:** `/root/steem-docker/data/witness_node_data_dir`  
- **Example:**

<code>export LOCAL_STEEM_LOCATION="/root/steem-docker"</code>

---

### `SEED_PORT` and `API_PORT`

- **SEED_PORT:** Port mapping for the Steem witness node seed port (default `-p 2001:2001`)  
- **API_PORT:** Port mapping for the HTTP RPC port (default `-p 8091:8091`)  

You can remove or change these in the script e.g. if you don't want to expose the API port.

---

### `ULIMIT_NUMBER`

- **Description:** Number of file descriptors allowed for the container.  
- **Default:** `999999`  

> Usually, you don't need to change this value.

---

## Usage

To customize the behavior of the script, set any of the environment variables listed above before running the script. If you do not set any of the variables, the script will use the default values.

- **DOCKER_NAME:** `steem`  
- **DOCKER_IMAGE:** `steem:latest`  
- **LOCAL_STEEM_LOCATION:** `/root/steem-docker/data/witness_node_data_dir`  

---

### Example with Custom Environment Variables

<code>export DOCKER_NAME="my_steem_node"</code>  
<code>export DOCKER_IMAGE="custom_steem_image:latest"</code>  
<code>export LOCAL_STEEM_LOCATION="/mnt/custom_steem_data"</code>

---

## Script Commands

### Start the Steem Witness Node

<code>./run.sh start</code>

- Starts the Steem witness node in a Docker container.  
- Maps the following ports by default:
  - `2001:2001` – Seed port  
  - `8091:8091` – HTTP RPC port  
- Mounts Steem data to `$LOCAL_STEEM_LOCATION` on the host.

---

### Stop the Steem Witness Node

<code>./run.sh stop</code>

- Stops the Steem witness node container gracefully with a timeout of 600 seconds.  
- Removes the container after stopping.  

---

### Force Kill the Steem Witness Node

<code>./run.sh kill</code>

- Immediately stops the container and removes it, regardless of its state.  

---

### Restart the Steem Witness Node

<code>./run.sh restart</code>

- Stops and then starts the container. Equivalent to running:

<code>./run.sh stop</code>  
<code>./run.sh start</code>

---

### Start a Test Steem Container

<code>./run.sh test</code>

- Starts the container interactively with a `/bin/bash` shell.  
- Useful for inspecting the container or running commands manually.

---

### Debug the Steem Witness Node

<code>./run.sh debug</code>

- Debug the running steem container

---

### Print Current Configuration

<code>./run.sh print</code>

- Prints the current parameters used by the script, including:
  - `DOCKER_NAME`  
  - `DOCKER_IMAGE`  
  - `LOCAL_STEEM_LOCATION`  
  - `SEED_PORT`  
  - `API_PORT`  
  - `DOCKER_ARGS`  
  - `ULIMIT_NUMBER`  

---

### Check Container Status

<code>./run.sh status</code>

- Displays detailed container information:
  - Running state  
  - Container ID  
  - Image name  
  - Ports  
  - Mounted volumes  
  - Ulimit and restart policy  
  - CPU and memory usage  

---

### View Logs of the Steem Witness Node

<code>./run.sh logs</code>

- Tails the last 100 lines of the container logs by default and follows new entries.  
- To show a different number of lines:

<code>./run.sh logs 500</code>

- To show all:

<code>./run.sh logs all</code>
