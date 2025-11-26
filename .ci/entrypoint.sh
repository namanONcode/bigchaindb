#!/bin/bash
# BigchainDB Entrypoint (external MongoDB backend)
# SPDX-License-Identifier: Apache-2.0
#
# This entrypoint connects to an EXTERNAL MongoDB server.
# BigchainDB does NOT start or manage MongoDB internally.

set -e

echo "===== BigchainDB Entrypoint (external MongoDB) ====="

# --------------------------------------------------------
# 1. Configuration from environment variables
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
# 3. Validate external MongoDB is reachable
# --------------------------------------------------------
echo "[INFO] Checking if MongoDB at $MONGODB_HOST:$MONGODB_PORT is reachable..."

retry_count=0
while ! nc -z "$MONGODB_HOST" "$MONGODB_PORT" 2>/dev/null; do
    retry_count=$((retry_count + 1))
    if [ "$retry_count" -ge "$MAX_RETRIES" ]; then
        echo "[ERROR] Cannot connect to MongoDB at $MONGODB_HOST:$MONGODB_PORT after $MAX_RETRIES attempts."
        echo "[ERROR] Please ensure an external MongoDB server is running and accessible."
        exit 1
    fi
    echo "[INFO] Waiting for MongoDB at $MONGODB_HOST:$MONGODB_PORT... (attempt $retry_count/$MAX_RETRIES)"
    sleep "$RETRY_INTERVAL"
done

echo "[INFO] MongoDB at $MONGODB_HOST:$MONGODB_PORT is reachable!"

# --------------------------------------------------------
# 4. Generate BigchainDB config with mongodb backend
# --------------------------------------------------------
echo "[INFO] Generating BigchainDB config with mongodb backend..."
bigchaindb -y configure mongodb
echo "[INFO] Config generated"
echo "[INFO] Using backend: mongodb (external)"

# --------------------------------------------------------
# 5. Optional ABCI testing mode (for CI)
# --------------------------------------------------------
if [ "$BIGCHAINDB_CI_ABCI" = "enable" ]; then
    echo "[INFO] ABCI CI mode requested — pausing for CI"
    sleep 3600
    exit 0
fi

# --------------------------------------------------------
# 6. Start BigchainDB node
#    Connects to external MongoDB server
# --------------------------------------------------------
echo "[INFO] Starting BigchainDB node..."
echo "[INFO] Connecting to external MongoDB at $MONGODB_HOST:$MONGODB_PORT"
echo "[INFO] BigchainDB will start on ${BIGCHAINDB_SERVER_BIND:-0.0.0.0:9984}"
exec bigchaindb -l DEBUG start
