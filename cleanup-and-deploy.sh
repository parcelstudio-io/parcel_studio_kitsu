#!/bin/bash

# Parcel Studio Kitsu - Complete Cleanup and Fresh Deployment
set -e

echo "🧹 Starting complete cleanup and fresh deployment..."

# Set variables
PROJECT_ID=${GCP_PROJECT_ID:-"parcel-studio-kitsu"}
CLUSTER_NAME=${GKE_CLUSTER_NAME:-"kitsu-cluster"}
ZONE=${GCP_ZONE:-"us-central1-a"}

echo "📋 Configuration:"
echo "  Project ID: $PROJECT_ID"
echo "  Cluster: $CLUSTER_NAME"
echo "  Zone: $ZONE"

# Step 1: Complete Cleanup
echo ""
echo "🗑️  Step 1: Deleting ALL existing resources..."

# Delete all deployments
kubectl delete deployments --all --force --grace-period=0

# Delete all services (except kubernetes default)
kubectl delete services --all --ignore-not-found=true
kubectl get services

# Delete all pods
kubectl delete pods --all --force --grace-period=0

# Delete all persistent volume claims
kubectl delete pvc --all

# Delete all secrets
kubectl delete secrets --all --ignore-not-found=true

# Wait for cleanup
echo "⏳ Waiting for cleanup to complete..."
sleep 30

# Verify cleanup
echo "📊 Checking cleanup status..."
kubectl get all
kubectl get pvc
kubectl get pv

echo ""
echo "✅ Cleanup complete!"

# Step 2: Fresh Deployment
echo ""
echo "🚀 Step 2: Fresh deployment starting..."

# Deploy using the working all-in-one configuration
cat > /tmp/kitsu-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kitsu-postgres
  labels:
    app: kitsu-postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kitsu-postgres
  template:
    metadata:
      labels:
        app: kitsu-postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13
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
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: kitsu-postgres
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
  type: ClusterIP

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kitsu-redis
  labels:
    app: kitsu-redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kitsu-redis
  template:
    metadata:
      labels:
        app: kitsu-redis
    spec:
      containers:
      - name: redis
        image: redis:6
        ports:
        - containerPort: 6379

---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
spec:
  selector:
    app: kitsu-redis
  ports:
    - protocol: TCP
      port: 6379
      targetPort: 6379
  type: ClusterIP

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kitsu-app
  labels:
    app: kitsu-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kitsu-app
  template:
    metadata:
      labels:
        app: kitsu-app
    spec:
      containers:
      - name: cgwire
        image: cgwire/cgwire:latest
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
        - containerPort: 80
        - containerPort: 5000
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 60
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 120
          periodSeconds: 30

---
apiVersion: v1
kind: Service
metadata:
  name: kitsu-service
spec:
  selector:
    app: kitsu-app
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer

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
      storage: 10Gi
EOF

echo "📦 Deploying Kitsu..."
kubectl apply -f /tmp/kitsu-deployment.yaml

# Step 3: Monitor Deployment
echo ""
echo "⏳ Step 3: Monitoring deployment progress..."

# Wait for deployments to be ready
echo "Waiting for PostgreSQL..."
kubectl wait --for=condition=available --timeout=300s deployment/kitsu-postgres

echo "Waiting for Redis..."
kubectl wait --for=condition=available --timeout=300s deployment/kitsu-redis

echo "Waiting for Kitsu application..."
kubectl wait --for=condition=available --timeout=600s deployment/kitsu-app

# Step 4: Get External IP
echo ""
echo "🌐 Step 4: Getting external access..."

EXTERNAL_IP=""
echo "Waiting for external IP to be assigned..."
while [ -z $EXTERNAL_IP ]; do
    echo "Checking for external IP..."
    EXTERNAL_IP=$(kubectl get svc kitsu-service --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
    [ -z "$EXTERNAL_IP" ] && sleep 10
done

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🎉 Parcel Studio Kitsu is now accessible at:"
echo "   http://$EXTERNAL_IP"
echo ""
echo "🔐 Default login credentials:"
echo "   Email: admin@example.com"
echo "   Password: mysecretpassword"
echo ""
echo "📊 To monitor your deployment:"
echo "   kubectl get all"
echo "   kubectl logs -l app=kitsu-app"
echo ""
echo "🗂️  Database will be automatically initialized on first access"
echo "🚀 Your team can now access Kitsu!"

# Cleanup temp file
rm -f /tmp/kitsu-deployment.yaml

echo ""
echo "🎯 Next Steps:"
echo "1. Visit http://$EXTERNAL_IP in your browser"
echo "2. Login with admin@example.com / mysecretpassword"  
echo "3. Create your production projects and team accounts"
echo "4. Configure your animation pipeline"