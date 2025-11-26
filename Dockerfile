# BigchainDB Docker Image
# Requires EXTERNAL MongoDB server - BigchainDB does NOT manage MongoDB internally
#
# Ubuntu 22.04 Base
FROM ubuntu:22.04

LABEL maintainer="namanoncode"

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.11 \
        python3.11-venv \
        python3.11-dev \
        python3-pip \
        build-essential \
        libssl-dev \
        libffi-dev \
        git \
        curl \
        netcat-openbsd \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# BigchainDB source
WORKDIR /usr/src/app
COPY . /usr/src/app

# Install BigchainDB and dependencies
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel && \
    pip3 install --no-cache-dir -e .

ENV PYTHONPATH=/usr/src/app:$PYTHONPATH

# BigchainDB environment configuration
# External MongoDB connection settings (defaults)
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
