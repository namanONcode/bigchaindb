#!/bin/bash
# Copyright © 
# BigchainDB Docker Entrypoint (Fedora + pyenv + MongoDB Embedded)
# SPDX-License-Identifier: Apache-2.0

set -e -x

# --------------------------------------------------------
# 1. Start MongoDB for localmongodb backend
# --------------------------------------------------------
mkdir -p /data/db
chmod -R 777 /data || true

# Start MongoDB in background
mongod --dbpath /data/db --bind_ip_all --nojournal --noprealloc &

# Allow MongoDB time to initialize
sleep 3


# --------------------------------------------------------
# 2. Reinstall BigchainDB in editable mode (SELinux fix)
# --------------------------------------------------------
pip install -q -e /usr/src/app

# Add app source directory to Python PATH
export PYTHONPATH=/usr/src/app:${PYTHONPATH}


# --------------------------------------------------------
# 3. Optional ABCI mode
# --------------------------------------------------------
if [[ ${BIGCHAINDB_CI_ABCI} == 'enable' ]]; then
    echo "ABCI CI mode enabled — sleeping..."
    sleep 3600
else
    # --------------------------------------------------------
    # 4. Start BigchainDB Node
    # --------------------------------------------------------
    bigchaindb -l DEBUG start
fi
