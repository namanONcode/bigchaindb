# BigchainDB Docker Image
# Requires external MongoDB server connection
#
# Ubuntu 20.04 Base (Python 3.8 default)
# Note: Using Ubuntu 20.04 because bigchaindb-abci==1.0.7 depends on gevent==21.1.2
# which only supports Python 2.7-3.9
FROM ubuntu:20.04

LABEL maintainer="namanoncode"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-dev \
    python3-venv \
    python3-pip \
    build-essential \
    libssl-dev \
    libffi-dev \
    curl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# BigchainDB source
WORKDIR /usr/src/app
COPY . /usr/src/app

# Upgrade pip first, then use python3 -m pip for reliable access to new pip
# This fixes packaging.version.InvalidVersion errors with older pip versions
RUN python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip install -e .

ENV PYTHONPATH=/usr/src/app

# BigchainDB environment configuration
# Requires external MongoDB server - configure via environment variables
ENV PYTHONUNBUFFERED=0
ENV BIGCHAINDB_DATABASE_BACKEND=mongodb
ENV BIGCHAINDB_DATABASE_HOST=localhost
ENV BIGCHAINDB_DATABASE_PORT=27017
ENV BIGCHAINDB_DATABASE_NAME=bigchain
ENV BIGCHAINDB_SERVER_BIND=0.0.0.0:9984

# Copy and set up entrypoint
COPY .ci/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# BigchainDB API port
EXPOSE 9984

ENTRYPOINT ["/entrypoint.sh"]
