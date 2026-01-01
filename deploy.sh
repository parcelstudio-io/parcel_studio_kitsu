#!/bin/bash

# Parcel Studio Kitsu GCP Deployment Script
set -e

echo "🚀 Starting Parcel Studio Kitsu deployment to GCP..."

# Check if required tools are installed
command -v gcloud >/dev/null 2>&1 || { echo "❌ gcloud CLI is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed. Aborting." >&2; exit 1; }

# Set variables
PROJECT_ID=${GCP_PROJECT_ID:-"parcel-studio-kitsu"}
CLUSTER_NAME=${GKE_CLUSTER_NAME:-"kitsu-cluster"}
ZONE=${GCP_ZONE:-"us-central1-a"}
REGION=${GCP_REGION:-"us-central1"}

echo "📋 Configuration:"
echo "  Project ID: $PROJECT_ID"
echo "  Cluster: $CLUSTER_NAME"
echo "  Zone: $ZONE"
echo "  Region: $REGION"

# Authenticate and set project
echo "🔐 Setting up GCP authentication..."
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "🔧 Enabling required GCP APIs..."
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com

# Create GKE cluster if it doesn't exist
echo "🏗️  Creating GKE cluster (if not exists)..."
if ! gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE >/dev/null 2>&1; then
    echo "Creating new GKE cluster..."
    gcloud container clusters create $CLUSTER_NAME \
        --zone=$ZONE \
        --num-nodes=3 \
        --machine-type=e2-standard-4 \
        --disk-size=50GB \
        --enable-autoscaling \
        --min-nodes=1 \
        --max-nodes=5
else
    echo "Cluster already exists, skipping creation..."
fi

# Get credentials for kubectl
echo "🔑 Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE

# Deploy to Kubernetes
echo "📦 Deploying Kitsu to Kubernetes..."
kubectl apply -f gcp-deployment.yaml

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/kitsu-postgres
kubectl wait --for=condition=available --timeout=600s deployment/kitsu-redis
kubectl wait --for=condition=available --timeout=600s deployment/kitsu-meilisearch
kubectl wait --for=condition=available --timeout=600s deployment/kitsu-zou
kubectl wait --for=condition=available --timeout=600s deployment/kitsu-zou-events
kubectl wait --for=condition=available --timeout=600s deployment/kitsu-frontend

# Get external IP
echo "🌐 Getting external IP address..."
EXTERNAL_IP=""
while [ -z $EXTERNAL_IP ]; do
    echo "Waiting for external IP..."
    EXTERNAL_IP=$(kubectl get svc kitsu-frontend-service --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
    [ -z "$EXTERNAL_IP" ] && sleep 10
done

echo "✅ Deployment complete!"
echo ""
echo "🎉 Parcel Studio Kitsu is now deployed and accessible at:"
echo "   http://$EXTERNAL_IP"
echo ""
echo "🔐 Default login credentials:"
echo "   Email: admin@example.com"
echo "   Password: mysecretpassword"
echo ""
echo "📊 To monitor your deployment:"
echo "   kubectl get pods"
echo "   kubectl get services"
echo "   kubectl logs -l app=kitsu-zou"
echo ""
echo "🛠️  To access kubectl dashboard:"
echo "   kubectl proxy"
echo "   Then visit: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"

# Initialize database (run once)
echo "🗄️  Initializing database..."
kubectl exec -it deployment/kitsu-zou -- python zou/cli.py init-db
kubectl exec -it deployment/kitsu-zou -- python zou/cli.py init-data
kubectl exec -it deployment/kitsu-zou -- python zou/cli.py create-admin admin@parcelstudio.com --password=parcelstudio2024

echo "🚀 Deployment complete! Your team can now access Kitsu at http://$EXTERNAL_IP"