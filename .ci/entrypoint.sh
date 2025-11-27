#!/bin/bash
set -e

echo "===== BigchainDB Entrypoint (External MongoDB + External Tendermint) ====="

# -----------------------------
# 1. Environment
# -----------------------------
MONGODB_HOST="${BIGCHAINDB_DATABASE_HOST:-localhost}"
MONGODB_PORT="${BIGCHAINDB_DATABASE_PORT:-27017}"
MONGODB_NAME="${BIGCHAINDB_DATABASE_NAME:-bigchain}"

echo "[INFO] MongoDB Host: $MONGODB_HOST"
echo "[INFO] MongoDB Port: $MONGODB_PORT"
echo "[INFO] MongoDB DB:   $MONGODB_NAME"

echo "[INFO] Tendermint RPC: ${BIGCHAINDB_TENDERMINT_HOST}:${BIGCHAINDB_TENDERMINT_PORT}"
echo "[INFO] BigchainDB ABCI will serve on port 26658"

export PYTHONPATH="/usr/src/app:$PYTHONPATH"

# -----------------------------
# 2. Wait for MongoDB
# -----------------------------
echo "[INFO] Waiting for MongoDB..."
until nc -z "$MONGODB_HOST" "$MONGODB_PORT"; do
  echo "[INFO] MongoDB not ready... retry"
  sleep 2
done
echo "[INFO] MongoDB is reachable."

# -----------------------------
# 3. DO NOT START TENDERMINT HERE
# -----------------------------
echo "[INFO] Tendermint runs in separate container. Skipping..."

# -----------------------------
# 4. Bind BigchainDB to correct interfaces
# -----------------------------
export BIGCHAINDB_SERVER_BIND="0.0.0.0:9984"   # HTTP API
export BIGCHAINDB_ABCI_BIND="0.0.0.0:26658"    # ABCI must be exposed inside Pod

echo "[INFO] BigchainDB API Bind: $BIGCHAINDB_SERVER_BIND"
echo "[INFO] BigchainDB ABCI Bind: $BIGCHAINDB_ABCI_BIND"
echo "[INFO] BigchainDB → Tendermint RPC at ${BIGCHAINDB_TENDERMINT_HOST}:${BIGCHAINDB_TENDERMINT_PORT}"

# -----------------------------
# 5. Start BigchainDB
# -----------------------------
echo "[INFO] Starting BigchainDB..."
exec bigchaindb -l DEBUG start
