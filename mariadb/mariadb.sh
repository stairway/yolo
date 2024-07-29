#!/bin/sh

set -euf

DOCKER_NETWORK="${DOCKER_NETWORK:-yolo-net}"

mariadb_server() {
  # mariadb server
  docker run \
    --rm \
    --name "$DOCKER_NETWORK" \
    --network=yolo-net \
    -e MARIADB_ROOT_PASSWORD=root \
    -p 3306:3306 \
    mariadb
}

mariadb_server

# mysql -uroot -proot -e "CREATE DATABASE mysql01"

# From remote container
# mysql -h mariadb-test -uvault-admin -pPassword123 -e "SHOW DATABASES"
