#!/bin/bash
# Copyright © 2020 Interplanetary Database Association e.V.,
# BigchainDB and IPDB software contributors.
# SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
# Code is Apache-2.0 and docs are CC-BY-4.0


set -e -x

# Wait for MongoDB to be ready
echo "Waiting for MongoDB..."
timeout 60 bash -c 'until python -c "from pymongo import MongoClient; MongoClient(\"mongodb://mongodb:27017\", serverSelectionTimeoutMS=2000).server_info()"; do sleep 2; done' || exit 1

# Configure BigchainDB if not already configured
if [ ! -f ~/.bigchaindb ]; then
  echo "Configuring BigchainDB for MongoDB..."
  bigchaindb configure mongodb
fi

# Show configuration for debugging
echo "BigchainDB Configuration:"
cat ~/.bigchaindb || echo "No config file found"

# Initialize database if needed
echo "Initializing BigchainDB database..."
bigchaindb init || echo "Database already initialized"

# Start BigchainDB ABCI server
echo "Starting BigchainDB with Tendermint ABCI server on 0.0.0.0:26658..."
exec bigchaindb start
