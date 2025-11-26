#!/bin/bash
# BigchainDB Entrypoint (Fedora + pyenv + embedded MongoDB)
# SPDX-License-Identifier: Apache-2.0

set -e -x

# --------------------------------------------------------
# 1. Prepare MongoDB runtime directory
# --------------------------------------------------------
mkdir -p /data/db
chmod -R 777 /data || true

# --------------------------------------------------------
# 2. Start MongoDB (required by localmongodb backend)
# --------------------------------------------------------
mongod \
    --dbpath /data/db \
    --bind_ip_all \
    --nojournal \
    --noprealloc \
    --quiet &

# Wait for mongod to accept connections
sleep 3


# --------------------------------------------------------
# 3. Ensure BigchainDB code is loaded in editable mode
#    (Fixes SELinux + mounted volumes + pyenv quirks)
# --------------------------------------------------------
pip install -q -e /usr/src/app

export PYTHONPATH="/usr/src/app:${PYTHONPATH}"


# --------------------------------------------------------
# 4. Optional: CI ABCI test mode
# --------------------------------------------------------
if [[ "${BIGCHAINDB_CI_ABCI}" == "enable" ]]; then
    echo "ABCI CI mode enabled — holding container for 1 hour..."
    sleep 3600
    exit 0
fi


# --------------------------------------------------------
# 5. Start BigchainDB node (localmongodb backend)
# --------------------------------------------------------
exec bigchaindb -l DEBUG start
