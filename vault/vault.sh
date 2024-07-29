#!/bin/sh

set -euf

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" 2>/dev/null && pwd )
DOCKER_MOUNT_DIR="${DOCKER_MOUNT_DIR:-$SCRIPT_DIR/.dockermount}"
DOCKER_NETWORK="${DOCKER_NETWORK:-yolo-net}"

__vault_server_dev() {
  local vault_server_dev=false
  [ "${1:-""}" != "dev" ] || vault_server_dev=true
  [ "${VAULT_SERVER_DEV:-$vault_server_dev}" = "true" ] || return $?
}

vault_server() {
  if __vault_server_dev "${1:-""}"; then
    # vault server --dev
    set -x
    docker run --rm --network="$DOCKER_NETWORK" --cap-add=IPC_LOCK --name vault-server-dev -p 8200:8200 \
      -e 'VAULT_DEV_ROOT_TOKEN_ID=myroot' \
      -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' \
      hashicorp/vault
  else
    # vault server
    # Replace binary with enterprise
    #   -v ./vault_1.17.0+ent_linux_amd64/vault:/bin/vault
    set -x
    docker run --rm --network="$DOCKER_NETWORK" --cap-add=IPC_LOCK --name vault-sever-test -p 8200:8200 \
      -e 'VAULT_LOCAL_CONFIG={"cluster_addr": "http://127.0.0.1:8201", "api_addr": "http://127.0.0.1:8200", "storage": {"raft": {"path": "/vault/file"}}, "listener": [{"tcp": { "address": "0.0.0.0:8200", "tls_disable": true}}], "default_lease_ttl": "168h", "max_lease_ttl": "720h", "ui": true}' \
      -v "$DOCKER_MOUNT_DIR/vault/file:/vault/file" \
      -v "$DOCKER_MOUNT_DIR/vault/config:/vault/config.d" \
      hashicorp/vault server
  fi
}

[ -n "${BASH_VERSION:-}" ] && vault_server "$@"

# From remote container
# export VAULT_ADDR='http://vault-server-dev:8200'
