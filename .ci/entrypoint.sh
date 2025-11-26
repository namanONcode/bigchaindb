#!/bin/bash
set -e

echo "===== BigchainDB Entrypoint (External MongoDB + Tendermint) ====="

# -----------------------------------------
# 1. Read Environment Variables
# -----------------------------------------
MONGODB_HOST="${BIGCHAINDB_DATABASE_HOST:-localhost}"
MONGODB_PORT="${BIGCHAINDB_DATABASE_PORT:-27017}"
MONGODB_NAME="${BIGCHAINDB_DATABASE_NAME:-bigchain}"

echo "[INFO] MongoDB Host: $MONGODB_HOST"
echo "[INFO] MongoDB Port: $MONGODB_PORT"
echo "[INFO] MongoDB Database: $MONGODB_NAME"

echo "[INFO] Tendermint RPC: ${BIGCHAINDB_TENDERMINT_HOST}:${BIGCHAINDB_TENDERMINT_PORT}"

# -----------------------------------------
# 2. Python environment
# -----------------------------------------
export PYTHONPATH="/usr/src/app:$PYTHONPATH"
echo "[INFO] PYTHONPATH: $PYTHONPATH"

# -----------------------------------------
# 3. Wait for MongoDB
# -----------------------------------------
echo "[INFO] Waiting for MongoDB..."
until nc -z "$MONGODB_HOST" "$MONGODB_PORT"; do
  sleep 2
  echo "[INFO] Waiting for MongoDB..."
done
echo "[INFO] MongoDB is reachable."

# -----------------------------------------
# 4. Start BigchainDB (starts ABCI on port 26658)
# -----------------------------------------
echo "[INFO] Starting BigchainDB node..."
exec bigchaindb start
