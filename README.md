<!---
Copyright © 2020 Interplanetary Database Association e.V.,
BigchainDB and IPDB software contributors.
SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
Code is Apache-2.0 and docs are CC-BY-4.0
--->

<!--- There is no shield to get the latest version
(including pre-release versions) from PyPI,
so show the latest GitHub release instead.
--->

[![Codecov branch](https://img.shields.io/codecov/c/github/bigchaindb/bigchaindb/master.svg)](https://codecov.io/github/bigchaindb/bigchaindb?branch=master)
[![Latest release](https://img.shields.io/github/release/bigchaindb/bigchaindb/all.svg)](https://github.com/bigchaindb/bigchaindb/releases)
[![Status on PyPI](https://img.shields.io/pypi/status/bigchaindb.svg)](https://pypi.org/project/BigchainDB/)
[![Travis branch](https://img.shields.io/travis/bigchaindb/bigchaindb/master.svg)](https://travis-ci.com/bigchaindb/bigchaindb)
[![Documentation Status](https://readthedocs.org/projects/bigchaindb-server/badge/?version=latest)](https://docs.bigchaindb.com/projects/server/en/latest/)
[![Join the chat at https://gitter.im/bigchaindb/bigchaindb](https://badges.gitter.im/bigchaindb/bigchaindb.svg)](https://gitter.im/bigchaindb/bigchaindb?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# BigchainDB Server

BigchainDB is the blockchain database. This repository is for _BigchainDB Server_.

## Quick Start with Docker

BigchainDB requires an **external MongoDB** server. The easiest way to run BigchainDB is using Docker Compose:

```bash
git clone https://github.com/bigchaindb/bigchaindb.git
cd bigchaindb
docker-compose up -d
```

BigchainDB API will be available at `http://localhost:9984/`.

## Docker Image

The BigchainDB Docker image is based on **Ubuntu 22.04** and requires an external MongoDB connection.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BIGCHAINDB_DATABASE_BACKEND` | `mongodb` | Database backend (only `mongodb` is supported) |
| `BIGCHAINDB_DATABASE_HOST` | `localhost` | MongoDB host address |
| `BIGCHAINDB_DATABASE_PORT` | `27017` | MongoDB port |
| `BIGCHAINDB_DATABASE_NAME` | `bigchain` | MongoDB database name |
| `BIGCHAINDB_SERVER_BIND` | `0.0.0.0:9984` | API server bind address |

### Running with Docker

```bash
# Start MongoDB first
docker run -d --name mongodb -p 27017:27017 mongo:4.4

# Run BigchainDB
docker run -d \
  --name bigchaindb \
  -e BIGCHAINDB_DATABASE_HOST=mongodb \
  -e BIGCHAINDB_DATABASE_PORT=27017 \
  -e BIGCHAINDB_DATABASE_NAME=bigchain \
  -p 9984:9984 \
  --link mongodb:mongodb \
  bigchaindb/bigchaindb
```

### Docker Compose Example

```yaml
version: '3'
services:
  mongodb:
    image: mongo:4.4
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db

  bigchaindb:
    image: bigchaindb/bigchaindb
    depends_on:
      - mongodb
    environment:
      BIGCHAINDB_DATABASE_BACKEND: mongodb
      BIGCHAINDB_DATABASE_HOST: mongodb
      BIGCHAINDB_DATABASE_PORT: 27017
      BIGCHAINDB_DATABASE_NAME: bigchain
      BIGCHAINDB_SERVER_BIND: 0.0.0.0:9984
    ports:
      - "9984:9984"

volumes:
  mongodb_data:
```

## The Basics

* [Try the Quickstart](https://docs.bigchaindb.com/projects/server/en/latest/quickstart.html)
* [Read the BigchainDB 2.0 whitepaper](https://www.bigchaindb.com/whitepaper/)
* [Check out the _Hitchiker's Guide to BigchainDB_](https://www.bigchaindb.com/developers/guide/)

## Run and Test BigchainDB Server from the `master` Branch

Running and testing the latest version of BigchainDB Server is easy. Make sure you have a recent version of [Docker Compose](https://docs.docker.com/compose/install/) installed. When you are ready, fire up a terminal and run:

```text
git clone https://github.com/bigchaindb/bigchaindb.git
cd bigchaindb
make run
```

BigchainDB should be reachable now on `http://localhost:9984/`.

There are also other commands you can execute:

* `make start`: Run BigchainDB from source and daemonize it (stop it with `make stop`).
* `make stop`: Stop BigchainDB.
* `make logs`: Attach to the logs.
* `make test`: Run all unit and acceptance tests.
* `make test-unit-watch`: Run all tests and wait. Every time you change code, tests will be run again.
* `make cov`: Check code coverage and open the result in the browser.
* `make doc`: Generate HTML documentation and open it in the browser.
* `make clean`: Remove all build, test, coverage and Python artifacts.
* `make reset`: Stop and REMOVE all containers. WARNING: you will LOSE all data stored in BigchainDB.

To view all commands available, run `make`.

## Local Development Setup

### Prerequisites

- Python 3.8+ (Python 3.11 recommended)
- MongoDB 4.4+
- Tendermint v0.31.5

### Installation

```bash
# Clone the repository
git clone https://github.com/bigchaindb/bigchaindb.git
cd bigchaindb

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -e .[dev]

# Configure BigchainDB
bigchaindb -y configure mongodb
```

### Running Locally

```bash
# Start MongoDB
mongod --dbpath /path/to/data

# In another terminal, start BigchainDB
bigchaindb start
```

## Links for Everyone

* [BigchainDB.com](https://www.bigchaindb.com/) - the main BigchainDB website, including newsletter signup
* [Roadmap](https://github.com/bigchaindb/org/blob/master/ROADMAP.md)
* [Blog](https://medium.com/the-bigchaindb-blog)
* [Twitter](https://twitter.com/BigchainDB)

## Links for Developers

* [All BigchainDB Documentation](https://docs.bigchaindb.com/en/latest/)
* [BigchainDB Server Documentation](https://docs.bigchaindb.com/projects/server/en/latest/index.html)
* [CONTRIBUTING.md](.github/CONTRIBUTING.md) - how to contribute
* [Community guidelines](CODE_OF_CONDUCT.md)
* [Open issues](https://github.com/bigchaindb/bigchaindb/issues)
* [Open pull requests](https://github.com/bigchaindb/bigchaindb/pulls)
* [Gitter chatroom](https://gitter.im/bigchaindb/bigchaindb)

## Legal

* [Licenses](LICENSES.md) - open source & open content
* [Imprint](https://www.bigchaindb.com/imprint/)
* [Contact Us](https://www.bigchaindb.com/contact/)
