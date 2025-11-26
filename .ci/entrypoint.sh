#!/bin/bash
set -e

echo "===== BigchainDB Entrypoint (External MongoDB + Tendermint) ====="

# -----------------------------
# 1. Read Environment Variables
# -----------------------------
MONGODB_HOST="${BIGCHAINDB_DATABASE_HOST:-localhost}"
MONGODB_PORT="${BIGCHAINDB_DATABASE_PORT:-27017}"
MONGODB_NAME="${BIGCHAINDB_DATABASE_NAME:-bigchain}"

echo "[INFO] MongoDB Host: $MONGODB_HOST"
echo "[INFO] MongoDB Port: $MONGODB_PORT"
echo "[INFO] MongoDB DB:   $MONGODB_NAME"

# Tendermint ABCI will always be local
TENDERMINT_RPC="127.0.0.1:26657"
TENDERMINT_ABCI="127.0.0.1:26658"

echo "[INFO] Tendermint RPC will bind at $TENDERMINT_RPC"
echo "[INFO] Tendermint ABCI will bind at $TENDERMINT_ABCI"

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
# 4. Start Tendermint
# -----------------------------
echo "[INFO] Initializing Tendermint..."
tendermint init --home /tendermint >/dev/null

echo "[INFO] Starting Tendermint node..."
tendermint node \
  --home=/tendermint \
  --proxy_app="tcp://127.0.0.1:26658" \
  --rpc.laddr="tcp://0.0.0.0:26657" &
  
sleep 3

# -----------------------------
# 5. Start BigchainDB ABCI
# -----------------------------
echo "[INFO] Starting BigchainDB node (ABCI on 127.0.0.1:26658)..."

# BigchainDB must only bind locally (inside pod)
export BIGCHAINDB_SERVER_BIND="127.0.0.1:9984"

exec bigchaindb start
