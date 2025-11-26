# BigchainDB Docker Image
# Requires external MongoDB server connection
#
# Ubuntu 22.04 Base
FROM ubuntu:22.04

LABEL maintainer="namanoncode"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3-pip \
    build-essential \
    libssl-dev \
    libffi-dev \
    curl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as the default python
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# BigchainDB source
WORKDIR /usr/src/app
COPY . /usr/src/app

# Install BigchainDB
RUN pip3 install --upgrade pip setuptools wheel && \
    pip3 install -e .

ENV PYTHONPATH=/usr/src/app:$PYTHONPATH

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
