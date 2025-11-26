# BigchainDB Docker Image
# Uses localmongodb backend - does NOT require external MongoDB server
#
# Fedora 41 Base
FROM fedora:41

LABEL maintainer="namanoncode"

# Install system dependencies
RUN dnf -y update && \
    dnf -y install \
        git \
        gcc \
        gcc-c++ \
        make \
        openssl-devel \
        bzip2 \
        bzip2-devel \
        libffi-devel \
        zlib-devel \
        readline-devel \
        sqlite-devel \
        tk-devel \
        xz-devel \
        libuuid-devel \
        wget \
        which \
        jq && \
    dnf clean all

# Install pyenv for Python version management
ENV PYENV_ROOT="/root/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PATH"

RUN git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT

RUN pyenv install 3.8.18 && \
    pyenv global 3.8.18

ENV PATH="$PYENV_ROOT/versions/3.8.18/bin:$PATH"

# BigchainDB source
WORKDIR /usr/src/app
COPY . /usr/src/app

RUN pip install --upgrade pip setuptools wheel && \
    pip install -e .

ENV PYTHONPATH=/usr/src/app:$PYTHONPATH

# Runtime data directory
# Note: Config is generated at runtime by entrypoint.sh, NOT at build time
# This prevents stale configs from being baked into the image
RUN mkdir -p /data/db && chmod -R 777 /data

VOLUME ["/data"]

# BigchainDB environment configuration
# IMPORTANT: Config file is generated at container startup (not build time)
# The entrypoint script regenerates config on every start to ensure
# localmongodb backend is always used
ENV PYTHONUNBUFFERED=0
ENV BIGCHAINDB_CONFIG_PATH=/data/.bigchaindb
ENV BIGCHAINDB_DATABASE_BACKEND=localmongodb
ENV BIGCHAINDB_SERVER_BIND=0.0.0.0:9984

# Copy and set up entrypoint
# The entrypoint handles:
# 1. Removing stale config files
# 2. Generating fresh config with localmongodb backend
# 3. Starting BigchainDB node
COPY .ci/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# BigchainDB API port
EXPOSE 9984

ENTRYPOINT ["/entrypoint.sh"]
