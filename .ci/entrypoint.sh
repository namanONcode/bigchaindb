apiVersion: apps/v1
kind: Deployment
metadata:
  name: bigchaindb
  namespace: reactivechaindb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bigchaindb
  template:
    metadata:
      labels:
        app: bigchaindb
    spec:
      volumes:
        - name: tmdata
          emptyDir: {}

      # ------------------------------------------------------
      # Tendermint init container
      # ------------------------------------------------------
      initContainers:
        - name: init-tendermint
          image: tendermint/tendermint:v0.31.5
          command:
            - sh
            - -c
            - |
              echo "[INIT] Tendermint initialization..."
              tendermint init --home /tendermint

              echo "[INIT] Patching Tendermint config..."

              # Tendermint → BigchainDB ABCI (SAME POD)  
              sed -i 's|proxy_app = "kvstore"|proxy_app = "tcp://127.0.0.1:26658"|' /tendermint/config/config.toml

              # RPC must be reachable for BigchainDB
              sed -i 's|laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|' /tendermint/config/config.toml

              # P2P
              sed -i 's|laddr = "tcp://0.0.0.0:26656"|laddr = "tcp://0.0.0.0:26656"|' /tendermint/config/config.toml

          volumeMounts:
            - name: tmdata
              mountPath: /tendermint

      containers:

        # ------------------------------------------------------
        # BigchainDB node (START FIRST)
        # ------------------------------------------------------
        - name: bigchaindb
          image: namanoncode/bigchaindb:latest
          command:
            - /bin/bash
            - -c
            - |
              set -ex
              echo "Waiting for MongoDB..."
              timeout 60 bash -c 'until python3 -c "from pymongo import MongoClient; MongoClient(\"mongodb://mongodb:27017\", serverSelectionTimeoutMS=2000).server_info()"; do sleep 2; done' || exit 1
              
              if [ ! -f ~/.bigchaindb ]; then
                echo "Configuring BigchainDB for MongoDB..."
                bigchaindb configure mongodb
              fi
              
              echo "BigchainDB Configuration:"
              cat ~/.bigchaindb || echo "No config file found"
              
              echo "Initializing BigchainDB database..."
              bigchaindb init || echo "Database already initialized"
              
              echo "Starting BigchainDB with Tendermint ABCI server..."
              exec bigchaindb start
          env:
            # Database configuration
            - name: BIGCHAINDB_DATABASE_BACKEND
              value: mongodb
            - name: BIGCHAINDB_DATABASE_HOST
              value: mongodb
            - name: BIGCHAINDB_DATABASE_PORT
              value: "27017"
            - name: BIGCHAINDB_DATABASE_NAME
              value: bigchain

            # Tendermint RPC INSIDE SAME POD
            - name: BIGCHAINDB_TENDERMINT_HOST
              value: "localhost"
            - name: BIGCHAINDB_TENDERMINT_PORT
              value: "26657"

            # HTTP API server bind (default is localhost:9984, we need 0.0.0.0)
            - name: BIGCHAINDB_SERVER_BIND
              value: "0.0.0.0:9984"

            # Logging
            - name: BIGCHAINDB_LOG_LEVEL_CONSOLE
              value: "debug"

            # WebSocket configuration
            - name: BIGCHAINDB_WSSERVER_SCHEME
              value: "ws"
            - name: BIGCHAINDB_WSSERVER_HOST
              value: "0.0.0.0"
            - name: BIGCHAINDB_WSSERVER_ADVERTISED_HOST
              value: "localhost"
            - name: BIGCHAINDB_WSSERVER_ADVERTISED_PORT
              value: "9985"
            - name: BIGCHAINDB_WSSERVER_PORT
              value: "9985"

          ports:
            - containerPort: 9984   # HTTP API
            - containerPort: 26658  # ABCI server listened by Tendermint
            - containerPort: 9985   # WebSocket

          readinessProbe:
            tcpSocket:
              port: 26658
            initialDelaySeconds: 10
            periodSeconds: 5
            timeoutSeconds: 3
            failureThreshold: 5

          livenessProbe:
            tcpSocket:
              port: 26658
            initialDelaySeconds: 30
            periodSeconds: 10

          volumeMounts:
            - name: tmdata
              mountPath: /tendermint

        # ------------------------------------------------------
        # Tendermint node
        # ------------------------------------------------------
        - name: tendermint
          image: tendermint/tendermint:v0.31.5
          command:
            - sh
            - -c
            - |
              echo "Waiting for BigchainDB ABCI server..."
              timeout=120
              while ! nc -z localhost 26658 2>/dev/null; do
                if [ $timeout -le 0 ]; then
                  echo "ERROR: BigchainDB ABCI server did not start within 120 seconds!"
                  exit 1
                fi
                echo "Waiting for ABCI server on port 26658... ($timeout seconds left)"
                sleep 3
                timeout=$((timeout-3))
              done
              
              # Extra wait to ensure ABCI server is fully ready
              echo "ABCI port is open, waiting 5 more seconds for full initialization..."
              sleep 5
              
              echo "Starting Tendermint..."
              tendermint node --home=/tendermint --proxy_app=tcp://127.0.0.1:26658
          volumeMounts:
            - name: tmdata
              mountPath: /tendermint
          ports:
            - containerPort: 26656
            - containerPort: 26657

---
apiVersion: v1
kind: Service
metadata:
  name: bigchaindb
  namespace: reactivechaindb
spec:
  selector:
    app: bigchaindb
  ports:
    - name: http
      port: 9984
      targetPort: 9984
