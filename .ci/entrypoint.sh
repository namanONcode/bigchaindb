#!/bin/bash
# BigchainDB Entrypoint (external MongoDB backend)
# SPDX-License-Identifier: Apache-2.0
#
# This entrypoint validates MongoDB connectivity and starts BigchainDB
# with an external MongoDB backend.

set -e

echo "===== BigchainDB Entrypoint (External MongoDB) ====="

# --------------------------------------------------------
# 1. Environment configuration defaults
# --------------------------------------------------------
MONGODB_HOST="${BIGCHAINDB_DATABASE_HOST:-localhost}"
MONGODB_PORT="${BIGCHAINDB_DATABASE_PORT:-27017}"
MONGODB_NAME="${BIGCHAINDB_DATABASE_NAME:-bigchain}"
MAX_RETRIES="${BIGCHAINDB_MONGODB_MAX_RETRIES:-30}"
RETRY_INTERVAL="${BIGCHAINDB_MONGODB_RETRY_INTERVAL:-2}"

echo "[INFO] MongoDB Host: $MONGODB_HOST"
echo "[INFO] MongoDB Port: $MONGODB_PORT"
echo "[INFO] MongoDB Database: $MONGODB_NAME"

# --------------------------------------------------------
# 2. Set up Python environment
# --------------------------------------------------------
export PYTHONPATH="/usr/src/app:$PYTHONPATH"
echo "[INFO] PYTHONPATH: $PYTHONPATH"

# --------------------------------------------------------
# 3. Wait for MongoDB to be available
# --------------------------------------------------------
echo "[INFO] Waiting for MongoDB at $MONGODB_HOST:$MONGODB_PORT..."

retries=0
until nc -z "$MONGODB_HOST" "$MONGODB_PORT" 2>/dev/null; do
    retries=$((retries + 1))
    if [ $retries -ge $MAX_RETRIES ]; then
        echo "[ERROR] MongoDB at $MONGODB_HOST:$MONGODB_PORT is not reachable after $MAX_RETRIES attempts"
        echo "[ERROR] Please ensure MongoDB is running and accessible"
        exit 1
    fi
    echo "[INFO] Attempt $retries/$MAX_RETRIES - MongoDB not ready, waiting ${RETRY_INTERVAL}s..."
    sleep $RETRY_INTERVAL
done

echo "[INFO] MongoDB is reachable at $MONGODB_HOST:$MONGODB_PORT"

# --------------------------------------------------------
# 4. Optional ABCI testing mode (for CI)
# --------------------------------------------------------
if [ "$BIGCHAINDB_CI_ABCI" = "enable" ]; then
    echo "[INFO] ABCI CI mode requested — pausing for CI"
    sleep 3600
    exit 0
fi

# --------------------------------------------------------
# 5. Start BigchainDB node
# --------------------------------------------------------
echo "[INFO] Starting BigchainDB node..."
echo "[INFO] Using external MongoDB backend at $MONGODB_HOST:$MONGODB_PORT"
echo "[INFO] BigchainDB will start on ${BIGCHAINDB_SERVER_BIND:-0.0.0.0:9984}"
exec bigchaindb -l DEBUG start
