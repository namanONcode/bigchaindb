# -------------------------------------------------------------------
# Fedora-based BigchainDB image (for your fork)
# - Compatible with SELinux (:z mounts)
# - Compatible with Kubernetes (K3s, Docker, containerd)
# - Modern Python 3.11
# - Uses your .ci/entrypoint.sh fixes
# -------------------------------------------------------------------

FROM fedora:41

LABEL maintainer="namanoncode"

# Install system deps
RUN dnf -y update && \
    dnf -y install \
        python3 \
        python3-pip \
        python3-devel \
        gcc \
        gcc-c++ \
        make \
        jq \
        libffi-devel \
        openssl-devel \
        git \
        which \
        tzdata && \
    dnf clean all

# Working directory
WORKDIR /usr/src/app

# Copy entire project
COPY . /usr/src/app

# Install BigchainDB in editable mode (for mounted volumes + SELinux)
RUN pip install --upgrade pip setuptools wheel && \
    pip install -e .

# Required for Fedora SELinux volume mounts
ENV PYTHONPATH=/usr/src/app:${PYTHONPATH}

# Use fixed entrypoint (your repo already contains .ci/entrypoint.sh)
COPY .ci/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# BigchainDB data + certs
VOLUME ["/data", "/certs"]

# BigchainDB defaults
ENV PYTHONUNBUFFERED=0
ENV BIGCHAINDB_CONFIG_PATH=/data/.bigchaindb
ENV BIGCHAINDB_SERVER_BIND=0.0.0.0:9984
ENV BIGCHAINDB_WSSERVER_HOST=0.0.0.0
ENV BIGCHAINDB_WSSERVER_SCHEME=ws
ENV BIGCHAINDB_WSSERVER_ADVERTISED_HOST=0.0.0.0
ENV BIGCHAINDB_WSSERVER_ADVERTISED_SCHEME=ws
ENV BIGCHAINDB_WSSERVER_ADVERTISED_PORT=9985

# Expose BigchainDB API
EXPOSE 9984

ENTRYPOINT ["/entrypoint.sh"]
