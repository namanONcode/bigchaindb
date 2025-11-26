# --------------------------------------------------------
# Fedora-based BigchainDB + MongoDB
# --------------------------------------------------------
FROM fedora:41

LABEL maintainer="namanoncode"

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
    cat <<EOF > /etc/yum.repos.d/mongodb-org-4.4.repo
[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/4.4/x86_64/
gpgcheck=0
enabled=1
EOF
    && \
    dnf -y install mongodb-org && \
    dnf clean all
