#!/bin/bash
# BigchainDB Entrypoint (External MongoDB)
set -e

echo "===== BigchainDB Entrypoint (External MongoDB + Tendermint) ====="

# -----------------------------------------
# 1. Read Environment Variables
# -----------------------------------------
MONGODB_HOST="${BIGCHAINDB_DATABASE_HOST:-localhost}"
MONGODB_PORT="${BIGCHAINDB_DATABASE_PORT:-27017}"
MONGODB_NAME="${BIGCHAINDB_DATABASE_NAME:-bigchain}"
MAX_RETRIES="${BIGCHAINDB_MONGODB_MAX_RETRIES:-30}"
RETRY_INTERVAL="${BIGCHAINDB_MONGODB_RETRY_INTERVAL:-2}"

TENDERMINT_PORT="${BIGCHAINDB_TENDERMINT_PORT:-26657}"

echo "[INFO] MongoDB Host: $MONGODB_HOST"
echo "[INFO] MongoDB Port: $MONGODB_PORT"
echo "[INFO] MongoDB Database: $MONGODB_NAME"

echo "[INFO] Tendermint RPC Port: $TENDERMINT_PORT"

# -----------------------------------------
# 2. Python environment
# -----------------------------------------
export PYTHONPATH="/usr/src/app:$PYTHONPATH"
echo "[INFO] PYTHONPATH: $PYTHONPATH"

# -----------------------------------------
# 3. Wait for MongoDB to start
# -----------------------------------------
echo "[INFO] Waiting for MongoDB at $MONGODB_HOST:$MONGODB_PORT..."

retries=0
until nc -z "$MONGODB_HOST" "$MONGODB_PORT" 2>/dev/null; do
    retries=$((retries + 1))
    if [ $retries -ge $MAX_RETRIES ]; then
        echo "[ERROR] MongoDB at $MONGODB_HOST:$MONGODB_PORT is not reachable."
        exit 1
    fi
    echo "[INFO] Attempt $retries/$MAX_RETRIES - waiting ${RETRY_INTERVAL}s..."
    sleep $RETRY_INTERVAL
done

echo "[INFO] MongoDB is reachable."

# -----------------------------------------
# 4. Start Tendermint Node
# -----------------------------------------
echo "[INFO] Initializing Tendermint..."
tendermint init > /dev/null

echo "[INFO] Starting Tendermint node..."
tendermint node --proxy_app=tcp://0.0.0.0:26658 &
sleep 3

# -----------------------------------------
# 5. Start BigchainDB Node
# -----------------------------------------
echo "[INFO] Starting BigchainDB node..."
exec bigchaindb -l DEBUG start
