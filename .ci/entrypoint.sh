#!/bin/bash
set -e

echo "===== BigchainDB Entrypoint (External MongoDB + External Tendermint) ====="

# -----------------------------
# 1. Read Environment Variables
# -----------------------------
MONGODB_HOST="${BIGCHAINDB_DATABASE_HOST:-localhost}"
MONGODB_PORT="${BIGCHAINDB_DATABASE_PORT:-27017}"
MONGODB_NAME="${BIGCHAINDB_DATABASE_NAME:-bigchain}"

echo "[INFO] MongoDB Host: $MONGODB_HOST"
echo "[INFO] MongoDB Port: $MONGODB_PORT"
echo "[INFO] MongoDB DB:   $MONGODB_NAME"

echo "[INFO] Tendermint RPC: ${BIGCHAINDB_TENDERMINT_HOST}:${BIGCHAINDB_TENDERMINT_PORT}"
echo "[INFO] ABCI (BigchainDB) will serve → Tendermint will connect to it."


# -----------------------------
# 2. Python PATH
# -----------------------------
export PYTHONPATH="/usr/src/app:$PYTHONPATH"
echo "[INFO] PYTHONPATH: $PYTHONPATH"


# -----------------------------
# 3. Wait for MongoDB
# -----------------------------
echo "[INFO] Waiting for MongoDB at $MONGODB_HOST:$MONGODB_PORT ..."
until nc -z "$MONGODB_HOST" "$MONGODB_PORT"; do
  echo "[INFO] MongoDB not up yet... retrying"
  sleep 2
done
echo "[INFO] MongoDB is reachable."


# -----------------------------
# 4. Do NOT start Tendermint here
# -----------------------------
echo "[INFO] Tendermint runs in its own Pod/Container. Not starting Tendermint inside BigchainDB container."


# -----------------------------
# 5. Configure BigchainDB Network Binds
# -----------------------------

# BigchainDB API (HTTP)
export BIGCHAINDB_SERVER_BIND="0.0.0.0:9984"

# ABCI app MUST LISTEN locally so Tendermint can connect
export BIGCHAINDB_ABCI_BIND="127.0.0.1:26658"

# Tendermint RPC location
# Tendermint will connect to BigchainDB via ABCI & RPC
export BIGCHAINDB_TENDERMINT_HOST="${BIGCHAINDB_TENDERMINT_HOST:-localhost}"
export BIGCHAINDB_TENDERMINT_PORT="${BIGCHAINDB_TENDERMINT_PORT:-26657}"

echo "[INFO] BigchainDB ABCI bind: $BIGCHAINDB_ABCI_BIND"
echo "[INFO] BigchainDB connecting to Tendermint RPC at $BIGCHAINDB_TENDERMINT_HOST:$BIGCHAINDB_TENDERMINT_PORT"


# -----------------------------
# 6. Start BigchainDB (ABCI + API)
# -----------------------------
echo "[INFO] Starting BigchainDB..."
exec bigchaindb -l DEBUG start
