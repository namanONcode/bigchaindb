#!/bin/bash
# BigchainDB Entrypoint (localmongodb backend only)
# SPDX-License-Identifier: Apache-2.0
#
# This entrypoint ensures BigchainDB ALWAYS uses the localmongodb backend
# by removing any stale config files and regenerating fresh config at startup.

set -e

echo "===== BigchainDB Entrypoint (localmongodb) ====="

# --------------------------------------------------------
# 1. Remove all existing config files to prevent stale configs
#    This ensures BigchainDB won't read old configs with "mongodb" backend
# --------------------------------------------------------
echo "[INFO] Removing any stale BigchainDB config files..."
rm -f /root/.bigchaindb
rm -f /usr/src/app/bigchaindb/.bigchaindb
rm -f /data/.bigchaindb
rm -f "$HOME/.bigchaindb"
echo "[INFO] Stale config files removed (if any existed)"

# --------------------------------------------------------
# 2. Prepare data directory for localmongodb
#    Note: localmongodb backend uses MongoDB internally but does NOT
#    require a separate MongoDB server on port 27017
# --------------------------------------------------------
mkdir -p /data/db
chmod -R 777 /data || true
echo "[INFO] Data directory prepared at /data"

# --------------------------------------------------------
# 3. Set up Python environment
# --------------------------------------------------------
export PYTHONPATH="/usr/src/app:$PYTHONPATH"
echo "[INFO] PYTHONPATH: $PYTHONPATH"

# --------------------------------------------------------
# 4. Generate fresh BigchainDB config with localmongodb backend
#    The -y flag auto-accepts defaults, ensuring no prompts
#    Config is written to the path specified by BIGCHAINDB_CONFIG_PATH
# --------------------------------------------------------
echo "[INFO] Generating fresh BigchainDB config with localmongodb backend..."
export BIGCHAINDB_CONFIG_PATH="${BIGCHAINDB_CONFIG_PATH:-/data/.bigchaindb}"
bigchaindb -y configure localmongodb
echo "[INFO] Config generated at: $BIGCHAINDB_CONFIG_PATH"
echo "[INFO] Using backend: localmongodb"

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
#    The localmongodb backend handles database internally
#    No external MongoDB connection to port 27017 needed
# --------------------------------------------------------
echo "[INFO] Starting BigchainDB node..."
echo "[INFO] MongoDB disabled (not needed for localmongodb backend)"
echo "[INFO] BigchainDB will start on ${BIGCHAINDB_SERVER_BIND:-0.0.0.0:9984}"
exec bigchaindb -l DEBUG start
