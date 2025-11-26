#!/bin/bash
# BigchainDB Entrypoint (Fedora + pyenv + embedded MongoDB)
# SPDX-License-Identifier: Apache-2.0

set -e

echo "===== BigchainDB + Embedded MongoDB Entrypoint ====="

# --------------------------------------------------------
# 1. Prepare MongoDB data directory
# --------------------------------------------------------
mkdir -p /data/db
chmod -R 777 /data || true
echo "[INFO] MongoDB data directory prepared at /data/db"


# --------------------------------------------------------
# 2. Start MongoDB (if available)
# --------------------------------------------------------
echo "[INFO] Starting embedded MongoDB..."

if command -v mongod >/dev/null 2>&1; then
    mongod --dbpath /data/db --bind_ip_all --quiet &
    MONGO_PID=$!
else
    echo "[WARNING] mongod is NOT installed – BigchainDB will still work using localmongodb backend."
    MONGO_PID=""
fi


# --------------------------------------------------------
# 3. Mongo readiness check (only if mongod exists)
# --------------------------------------------------------
if [ -n "$MONGO_PID" ]; then
    echo -n "[INFO] Checking if MongoDB is ready"

    for i in {1..30}; do
        if command -v mongo >/dev/null 2>&1; then
            if mongo --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
                echo " — READY"
                break
            fi
        fi

        echo -n "."
        sleep 1
    done

    if ! ps -p "$MONGO_PID" >/dev/null; then
        echo "[ERROR] MongoDB failed to start!"
        exit 1
    fi
else
    echo "[INFO] Skipping MongoDB readiness check (no mongod installed)"
fi


# --------------------------------------------------------
# 4. Install BigchainDB in editable mode (fix PATH + pyenv)
# --------------------------------------------------------
echo "[INFO] Installing BigchainDB in editable mode..."
pip install -q -e /usr/src/app || {
    echo "[WARNING] Editable install failed, using normal installation"
    pip install -q /usr/src/app
}

export PYTHONPATH="/usr/src/app:$PYTHONPATH"
echo "[INFO] PYTHONPATH updated: $PYTHONPATH"


# --------------------------------------------------------
# 5. Optional ABCI testing mode
# --------------------------------------------------------
if [ "$BIGCHAINDB_CI_ABCI" = "enable" ]; then
    echo "[INFO] ABCI CI mode requested — pausing for CI"
    sleep 3600
    exit 0
fi


# --------------------------------------------------------
# 6. Start BigchainDB node (backend = localmongodb)
# --------------------------------------------------------
echo "[INFO] Starting BigchainDB (localmongodb backend)"
exec bigchaindb -l DEBUG start
