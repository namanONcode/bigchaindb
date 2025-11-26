# BigchainDB Docker Image
# Requires external MongoDB server connection

FROM ubuntu:20.04

LABEL maintainer="namanoncode"

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
    tar \
    && rm -rf /var/lib/apt/lists/*

# Install Tendermint
RUN curl -L https://github.com/tendermint/tendermint/releases/download/v0.34.24/tendermint_0.34.24_linux_amd64.tar.gz \
    -o /tmp/tm.tar.gz && \
    tar -xvf /tmp/tm.tar.gz && \
    mv tendermint /usr/local/bin/tendermint && \
    chmod +x /usr/local/bin/tendermint && \
    rm /tmp/tm.tar.gz


# BigchainDB source
WORKDIR /usr/src/app
COPY . /usr/src/app

# Install BigchainDB
RUN python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip install -e .

ENV PYTHONPATH=/usr/src/app

# BigchainDB environment configuration
ENV PYTHONUNBUFFERED=0
ENV BIGCHAINDB_DATABASE_BACKEND=mongodb
ENV BIGCHAINDB_DATABASE_HOST=localhost
ENV BIGCHAINDB_DATABASE_PORT=27017
ENV BIGCHAINDB_DATABASE_NAME=bigchain
ENV BIGCHAINDB_SERVER_BIND=0.0.0.0:9984

# Tendermint host + port
ENV BIGCHAINDB_TENDERMINT_HOST=tendermint
ENV BIGCHAINDB_TENDERMINT_PORT=26657

# Copy custom entrypoint
COPY .ci/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose BigchainDB & Tendermint ports
# BigchainDB API
EXPOSE 9984
# Tendermint RPC
EXPOSE 26657
# Tendermint ABCI
EXPOSE 26658

ENTRYPOINT ["/entrypoint.sh"]

