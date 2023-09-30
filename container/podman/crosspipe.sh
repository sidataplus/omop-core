#!/bin/bash

# Determine the script's current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define the service names
POSTGRES_SERVICE="crosspipe-pg"
BASHCLI_SERVICE="crosspipe-cli"

# Check for the correct number of arguments
if [ $# -lt 1 ] || [ $# -gt 3 ]; then
  echo "Usage: $0 <up|stop|down> [-v] [options]"
  exit 1
fi

# Extract the command (up, stop, or down)
COMMAND="$1"
shift 1

# Initialize flags
VOLUME_FLAG=""

# Check for additional flags
while getopts "v" opt; do
  case $opt in
    v)
      VOLUME_FLAG="-v"
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
  esac
done

# Function to start the services
start_services() {
  # Start PostgreSQL in detached mode
  echo "Starting PostgreSQL in detached mode..."
  podman-compose -f "$SCRIPT_DIR/crosspipe-compose.yaml" up -d $POSTGRES_SERVICE

  # Start Bash CLI in the foreground
  echo "Starting Bash CLI in the foreground..."
  podman-compose -f "$SCRIPT_DIR/crosspipe-compose.yaml" up $BASHCLI_SERVICE
}

# Function to stop the services
stop_services() {
  # Stop PostgreSQL
  echo "Stopping PostgreSQL..."
  podman-compose -f "$SCRIPT_DIR/crosspipe-compose.yaml" stop $POSTGRES_SERVICE

  # Stop Bash CLI
  echo "Stopping Bash CLI..."
  podman-compose -f "$SCRIPT_DIR/crosspipe-compose.yaml" stop $BASHCLI_SERVICE
}

# Function to stop and remove volumes (if -v flag is used)
down_services() {
  # Stop and remove containers
  echo "Stopping and removing containers..."
  podman-compose -f "$SCRIPT_DIR/crosspipe-compose.yaml" down $VOLUME_FLAG

  if [ "$VOLUME_FLAG" == "-v" ]; then
    # Remove volumes
    echo "Removing volumes..."
    podman-compose -f "$SCRIPT_DIR/crosspipe-compose.yaml" down -v
  fi
}

# Check the command
case "$COMMAND" in
  up)
    start_services
    ;;
  stop)
    stop_services
    ;;
  down)
    down_services
    ;;
  *)
    echo "Usage: $0 <up|stop|down> [-v] [options]"
    exit 1
    ;;
esac

exit 0
