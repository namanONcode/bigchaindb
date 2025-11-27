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
echo "[INFO] ABCI will connect from BigchainDB → Tendermint"

# -----------------------------
# 2. Python PATH
# -----------------------------
export PYTHONPATH="/usr/src/app:$PYTHONPATH"
echo "[INFO] PYTHONPATH: $PYTHONPATH"

# -----------------------------
# 3. Wait for MongoDB
# -----------------------------
echo "[INFO] Waiting for MongoDB..."
until nc -z "$MONGODB_HOST" "$MONGODB_PORT"; do
  echo "[INFO] MongoDB not up yet..."
  sleep 2
done
echo "[INFO] MongoDB is reachable."

# -----------------------------
# 4. DO NOT START TENDERMINT HERE
# -----------------------------
echo "[INFO] Tendermint runs in its own container — skipping internal start."

# -----------------------------
# 5. Start BigchainDB ABCI + API
# -----------------------------
echo "[INFO] Starting BigchainDB..."
exec bigchaindb start
