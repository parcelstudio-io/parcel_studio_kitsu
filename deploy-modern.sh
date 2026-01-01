#!/bin/bash

# Modern Kitsu Deployment with Updated Components
set -e

echo "🚀 Deploying Modern Kitsu with Updated Components..."

# Step 1: Complete Cleanup
echo "🧹 Cleaning up existing deployment..."
kubectl delete deployments --all --force --grace-period=0 2>/dev/null || true
kubectl delete services --all --ignore-not-found=true 2>/dev/null || true
kubectl delete pods --all --force --grace-period=0 2>/dev/null || true
kubectl delete pvc --all 2>/dev/null || true

echo "⏳ Waiting for cleanup..."
sleep 30

# Step 2: Deploy Modern Stack
echo "📦 Deploying modern Kitsu stack..."

cat > /tmp/modern-kitsu.yaml << 'EOF'
# PostgreSQL Database
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        env:
        - name: POSTGRES_DB
          value: "zoudb"
        - name: POSTGRES_USER
          value: "postgres"
        - name: POSTGRES_PASSWORD
          value: "parcelstudio2025"
        - name: PGDATA
          value: "/var/lib/postgresql/data/pgdata"
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
        readinessProbe:
          exec:
            command: ["pg_isready", "-U", "postgres", "-d", "zoudb"]
          initialDelaySeconds: 15
          periodSeconds: 5
      volumes:
      - name: postgres-data
        persistentVolumeClaim:
          claimName: postgres-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432

---
# Redis Cache
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379

---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379

---
# Zou API Backend (using Python base image with manual install)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zou-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zou-api
  template:
    metadata:
      labels:
        app: zou-api
    spec:
      initContainers:
      - name: wait-for-postgres
        image: postgres:15
        command: ['sh', '-c', 'until pg_isready -h postgres-service -p 5432 -U postgres; do sleep 1; done']
      containers:
      - name: zou
        image: python:3.11-slim
        workingDir: /app
        command: ['sh', '-c']
        args:
        - |
          apt-get update && apt-get install -y git build-essential libpq-dev && \
          git clone https://github.com/cgwire/zou.git . && \
          pip install -r requirements.txt && \
          python zou/cli.py init-db || echo "DB already initialized" && \
          python zou/cli.py init-data || echo "Data already initialized" && \
          python zou/cli.py create-admin admin@parcelstudio.com --password=parcelstudio2025 || echo "Admin already exists" && \
          gunicorn -b 0.0.0.0:5000 zou.app:app
        env:
        - name: DB_HOST
          value: "postgres-service"
        - name: DB_PORT
          value: "5432"
        - name: DB_USERNAME
          value: "postgres"
        - name: DB_PASSWORD
          value: "parcelstudio2025"
        - name: DB_DATABASE
          value: "zoudb"
        - name: KV_HOST
          value: "redis-service"
        - name: KV_PORT
          value: "6379"
        - name: SECRET_KEY
          value: "parcelstudiosecretkey2025"
        ports:
        - containerPort: 5000
        readinessProbe:
          httpGet:
            path: /api
            port: 5000
          initialDelaySeconds: 60
          periodSeconds: 10

---
apiVersion: v1
kind: Service
metadata:
  name: zou-service
spec:
  selector:
    app: zou-api
  ports:
  - port: 5000
    targetPort: 5000

---
# Kitsu Frontend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kitsu-frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kitsu-frontend
  template:
    metadata:
      labels:
        app: kitsu-frontend
    spec:
      containers:
      - name: kitsu
        image: node:18-alpine
        workingDir: /app
        command: ['sh', '-c']
        args:
        - |
          apk add --no-cache git && \
          git clone https://github.com/cgwire/kitsu.git . && \
          npm install && \
          npm run build && \
          npx serve -s dist -l 80
        env:
        - name: KITSU_API_TARGET
          value: "http://zou-service:5000"
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: kitsu-service
spec:
  selector:
    app: kitsu-frontend
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80

---
# Persistent Volume Claims
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF

kubectl apply -f /tmp/modern-kitsu.yaml

# Step 3: Monitor Deployment
echo "⏳ Monitoring deployment..."

echo "Waiting for PostgreSQL..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres

echo "Waiting for Redis..."
kubectl wait --for=condition=available --timeout=300s deployment/redis

echo "Waiting for Zou API..."
kubectl wait --for=condition=available --timeout=600s deployment/zou-api

echo "Waiting for Kitsu Frontend..."
kubectl wait --for=condition=available --timeout=600s deployment/kitsu-frontend

# Step 4: Get External IP
echo "🌐 Getting external access..."
EXTERNAL_IP=""
while [ -z $EXTERNAL_IP ]; do
    echo "Waiting for external IP..."
    EXTERNAL_IP=$(kubectl get svc kitsu-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    [ -z "$EXTERNAL_IP" ] && sleep 10
done

echo ""
echo "✅ Modern Kitsu deployment complete!"
echo ""
echo "🎉 Access your Kitsu instance at:"
echo "   http://$EXTERNAL_IP"
echo ""
echo "🔐 Login credentials:"
echo "   Email: admin@parcelstudio.com"
echo "   Password: parcelstudio2025"
echo ""
echo "📊 Monitor deployment:"
echo "   kubectl get pods"
echo "   kubectl logs -l app=zou-api"
echo "   kubectl logs -l app=kitsu-frontend"

# Cleanup
rm -f /tmp/modern-kitsu.yaml