#!/bin/bash
# BigchainDB Entrypoint (Fedora + pyenv + embedded MongoDB)
# SPDX-License-Identifier: Apache-2.0

set -e

echo "===== BigchainDB + MongoDB (Fedora Embedded) Entrypoint ====="

# --------------------------------------------------------
# 1. Prepare MongoDB data directory
# --------------------------------------------------------
mkdir -p /data/db
chmod -R 777 /data || true

echo "[INFO] MongoDB data directory prepared."

# --------------------------------------------------------
# 2. Start MongoDB
# --------------------------------------------------------
echo "[INFO] Starting embedded MongoDB..."
mongod --dbpath /data/db --bind_ip_all --quiet &

MONGO_PID=$!

# --------------------------------------------------------
# 3. MongoDB readiness check (better than sleep)
# --------------------------------------------------------
echo -n "[INFO] Waiting for MongoDB to be ready"
for i in {1..30}; do
    if mongo --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
        echo " — READY"
        break
    fi
    echo -n "."
    sleep 1
done

if ! ps -p $MONGO_PID >/dev/null; then
    echo "[ERROR] MongoDB failed to start!"
    exit 1
fi


# --------------------------------------------------------
# 4. Ensure BigchainDB installed in editable/development mode
# --------------------------------------------------------
echo "[INFO] Ensuring BigchainDB is installed (editable mode)..."
pip install -q -e /usr/src/app || {
    echo "[WARNING] Editable install failed; attempting normal install"
    pip install .
}

export PYTHONPATH="/usr/src/app:${PYTHONPATH}"

echo "[INFO] PYTHONPATH set to: $PYTHONPATH"


# --------------------------------------------------------
# 5. Optional ABCI CI mode
# --------------------------------------------------------
if [[ "${BIGCHAINDB_CI_ABCI}" == "enable" ]]; then
    echo "[INFO] ABCI CI mode enabled — holding container for 1 hour..."
    sleep 3600
    exit 0
fi


# --------------------------------------------------------
# 6. Start BigchainDB
# --------------------------------------------------------
echo "[INFO] Starting BigchainDB (localmongodb backend)..."
exec bigchaindb -l DEBUG start
