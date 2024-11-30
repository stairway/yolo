#!/bin/sh

set -euf

# Create network
# docker network create --driver <driver> <network-name>
docker_network_create() {
  local network="${1:-""}"
  if [ -z "$network" ]; then
    read -r -p "Network Name or ID: " network
  fi
  [ -n "$network" ] || return $?
  printf "%s: %s\n" "Selected network Name or ID" "$network" >&2
  local _network=$(docker network ls --no-trunc | grep --color=never "$network" | awk '{print $1}')
  [ -n "$_network" ] && \
    echo "$_network" || \
    (set -x; docker network create --driver bridge "$network")
}

# Connect/Disconnect container to/from network
# docker network <connect|disconnect> <network> <container>"
docker_network_connect() {
  local network="${1:-""}"
  [ -n "$network" ] || return $?
  local container="${2:-""}"
  if [ -z "$container" ]; then
    printf "%s: %s\n" "Network Name or ID" "$network" >&2
    read -r -p "Container Name or ID: " container
  fi
  [ -n "$container" ] || return $?
  printf "%s: %s\n" "Selected container Name or ID" "$container" >&2
  (set -x; docker network connect "$network" "$container")
}

# Create network and send output to network connect
docker_network_connect "$(docker_network_create)"
