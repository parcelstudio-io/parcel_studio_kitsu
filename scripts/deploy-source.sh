#!/bin/bash

# Parcel Studio Kitsu - Source-Based GCP Deployment
set -e

echo "🚀 Deploying Parcel Studio Kitsu from Source to GCP..."

# Configuration
PROJECT_ID=${GCP_PROJECT_ID:-"parcel-studio-kitsu"}
CLUSTER_NAME=${GKE_CLUSTER_NAME:-"kitsu-cluster"}
ZONE=${GCP_ZONE:-"us-central1-a"}

echo "📋 Configuration:"
echo "  Project ID: $PROJECT_ID"
echo "  Cluster: $CLUSTER_NAME" 
echo "  Zone: $ZONE"

# Step 1: Build Frontend
echo ""
echo "📦 Step 1: Building Kitsu frontend from source..."

cd src/kitsu
npm install
npm run build
cd ../..

# Step 2: Create Docker images from source
echo ""
echo "🐳 Step 2: Creating Docker images from source..."

# Build Zou backend image
cat > Dockerfile.zou << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy source code
COPY zou-backend/zou/ .

# Install Python dependencies
RUN pip install -r requirements.txt

# Expose port
EXPOSE 5000

# Start command
CMD ["gunicorn", "-b", "0.0.0.0:5000", "zou.app:app"]
EOF

# Build Kitsu frontend image
cat > Dockerfile.kitsu << 'EOF'
FROM nginx:alpine

# Copy built frontend
COPY src/kitsu/dist/ /usr/share/nginx/html/

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
EOF

# Create nginx configuration
cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;

    # Serve static files
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    # Proxy API requests to Zou backend
    location /api/ {
        proxy_pass http://zou-service:5000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Build images
echo "Building Docker images..."
docker build -f Dockerfile.zou -t gcr.io/$PROJECT_ID/parcel-zou:latest .
docker build -f Dockerfile.kitsu -t gcr.io/$PROJECT_ID/parcel-kitsu:latest .

# Push to Google Container Registry
echo "Pushing images to GCR..."
gcloud auth configure-docker
docker push gcr.io/$PROJECT_ID/parcel-zou:latest
docker push gcr.io/$PROJECT_ID/parcel-kitsu:latest

# Step 3: Deploy to Kubernetes
echo ""
echo "☸️  Step 3: Deploying to Kubernetes..."

# Create source-based deployment manifest
cat > /tmp/source-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  labels:
    app: postgres
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
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  labels:
    app: redis
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
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zou-api
  labels:
    app: zou-api
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
      - name: init-db
        image: gcr.io/$PROJECT_ID/parcel-zou:latest
        command: ['sh', '-c']
        args:
        - |
          python zou/cli.py init-db || echo "DB already initialized"
          python zou/cli.py init-data || echo "Data already initialized"
          python zou/cli.py create-admin admin@parcelstudio.com --password=parcelstudio2025 || echo "Admin already exists"
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
      containers:
      - name: zou
        image: gcr.io/$PROJECT_ID/parcel-zou:latest
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
          initialDelaySeconds: 30
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
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kitsu-frontend
  labels:
    app: kitsu-frontend
spec:
  replicas: 2
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
        image: gcr.io/$PROJECT_ID/parcel-kitsu:latest
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
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
EOF

# Get kubectl credentials
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE

# Apply the deployment
kubectl apply -f /tmp/source-deployment.yaml

# Step 4: Wait for deployment
echo ""
echo "⏳ Step 4: Waiting for deployment to complete..."

kubectl wait --for=condition=available --timeout=300s deployment/postgres
kubectl wait --for=condition=available --timeout=300s deployment/redis  
kubectl wait --for=condition=available --timeout=600s deployment/zou-api
kubectl wait --for=condition=available --timeout=600s deployment/kitsu-frontend

# Step 5: Get external IP
echo ""
echo "🌐 Step 5: Getting external access..."

EXTERNAL_IP=""
while [ -z $EXTERNAL_IP ]; do
    echo "Waiting for external IP..."
    EXTERNAL_IP=\$(kubectl get svc kitsu-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    [ -z "\$EXTERNAL_IP" ] && sleep 10
done

# Cleanup temporary files
rm -f Dockerfile.zou Dockerfile.kitsu nginx.conf /tmp/source-deployment.yaml

echo ""
echo "✅ Source-based deployment complete!"
echo ""
echo "🎉 Parcel Studio Kitsu (built from source) is accessible at:"
echo "   http://\$EXTERNAL_IP"
echo ""
echo "🔐 Login credentials:"
echo "   Email: admin@parcelstudio.com"
echo "   Password: parcelstudio2025"
echo ""
echo "📊 Source code deployed:"
echo "   • Frontend: Built from src/kitsu/"
echo "   • Backend: Built from zou-backend/zou/"
echo "   • Container images: gcr.io/$PROJECT_ID/"
echo ""
echo "🛠️  To update deployment:"
echo "   1. Make changes to source code"
echo "   2. Run this script again"
echo "   3. Images will be rebuilt and redeployed"
echo ""
echo "🚀 Your team can now access the custom Kitsu build!"