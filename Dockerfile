# --------------------------------------------------------
# Fedora-based BigchainDB image WITH embedded MongoDB
# Python 3.8 via pyenv + SELinux-compatible volumes
# --------------------------------------------------------

FROM fedora:41

LABEL maintainer="namanoncode"

# --------------------------------------------------------
# Install system dependencies + Fedoras own MongoDB packages
# --------------------------------------------------------
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
        jq \
        mongodb-server \
        mongodb && \
    dnf clean all

# --------------------------------------------------------
# Install pyenv + Python 3.8.18
# --------------------------------------------------------
ENV PYENV_ROOT="/root/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PATH"

RUN git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT

RUN dnf -y install patch && \
    $PYENV_ROOT/bin/pyenv install 3.8.18 && \
    $PYENV_ROOT/bin/pyenv global 3.8.18

ENV PATH="$PYENV_ROOT/versions/3.8.18/bin:$PATH"

# --------------------------------------------------------
# Install BigchainDB from source
# --------------------------------------------------------
WORKDIR /usr/src/app
COPY . /usr/src/app

RUN pip install --upgrade pip setuptools wheel && \
    pip install -e .

ENV PYTHONPATH=/usr/src/app:$PYTHONPATH

# --------------------------------------------------------
# Runtime directories
# --------------------------------------------------------
RUN mkdir -p /data/db && chmod -R 777 /data

VOLUME ["/data"]

# --------------------------------------------------------
# Environment Variables
# --------------------------------------------------------
ENV PYTHONUNBUFFERED=0
ENV BIGCHAINDB_CONFIG_PATH=/data/.bigchaindb
ENV BIGCHAINDB_SERVER_BIND=0.0.0.0:9984
ENV BIGCHAINDB_DATABASE_BACKEND=localmongodb

# --------------------------------------------------------
# Entry Script
# --------------------------------------------------------
COPY .ci/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9984

ENTRYPOINT ["/entrypoint.sh"]
