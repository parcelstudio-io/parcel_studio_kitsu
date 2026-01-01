#!/bin/bash

# Parcel Studio Kitsu - Development Build from Source
set -e

echo "🔧 Starting Parcel Studio Kitsu Development Build..."

# Check prerequisites
command -v node >/dev/null 2>&1 || { echo "❌ Node.js is required but not installed. Aborting." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Python 3 is required but not installed. Aborting." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Aborting." >&2; exit 1; }

echo "✅ Prerequisites check passed"

# Step 1: Setup development database
echo ""
echo "🗄️  Step 1: Setting up development database..."

# Start PostgreSQL and Redis for development
docker run -d --name dev-postgres \
    -e POSTGRES_DB=zoudb \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=devpassword123 \
    -p 5432:5432 \
    postgres:15 2>/dev/null || echo "PostgreSQL container already running"

docker run -d --name dev-redis \
    -p 6379:6379 \
    redis:7-alpine 2>/dev/null || echo "Redis container already running"

echo "⏳ Waiting for database to be ready..."
sleep 10

# Step 2: Setup Zou Backend
echo ""
echo "🐍 Step 2: Setting up Zou backend from source..."

cd zou-backend/zou

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt

# Set environment variables for development
export DB_HOST=localhost
export DB_PORT=5432
export DB_USERNAME=postgres
export DB_PASSWORD=devpassword123
export DB_DATABASE=zoudb
export KV_HOST=localhost
export KV_PORT=6379
export SECRET_KEY=dev-secret-key-parcel-studio

# Initialize database
echo "Initializing database..."
python zou/cli.py init-db || echo "Database already initialized"
python zou/cli.py init-data || echo "Data already initialized"
python zou/cli.py create-admin admin@parcelstudio.com --password=parcelstudio2025 || echo "Admin user already exists"

# Start Zou API in background
echo "Starting Zou API server..."
gunicorn -b 0.0.0.0:5000 --daemon --pid zou.pid zou.app:app
echo "✅ Zou API running at http://localhost:5000"

cd ../..

# Step 3: Setup Kitsu Frontend
echo ""
echo "⚛️  Step 3: Setting up Kitsu frontend from source..."

cd src/kitsu

# Install dependencies
echo "Installing Node.js dependencies..."
npm install

# Set environment variables for development
export VITE_API_URL=http://localhost:5000

# Start development server in background
echo "Starting Kitsu development server..."
npm run dev &
KITSU_PID=$!
echo $KITSU_PID > kitsu.pid

echo "✅ Kitsu frontend starting at http://localhost:5173"

cd ../..

# Step 4: Development ready
echo ""
echo "🎉 Development environment ready!"
echo ""
echo "📊 Services:"
echo "   • Kitsu Frontend: http://localhost:5173"
echo "   • Zou API: http://localhost:5000"
echo "   • PostgreSQL: localhost:5432"
echo "   • Redis: localhost:6379"
echo ""
echo "🔐 Login credentials:"
echo "   • Email: admin@parcelstudio.com"
echo "   • Password: parcelstudio2025"
echo ""
echo "🛠️  Development commands:"
echo "   • Stop services: ./scripts/stop-dev.sh"
echo "   • View logs: ./scripts/dev-logs.sh"
echo "   • Restart: ./scripts/restart-dev.sh"
echo ""
echo "📝 Source code locations:"
echo "   • Frontend: src/kitsu/"
echo "   • Backend: zou-backend/zou/"
echo ""
echo "💡 Hot reloading is enabled - changes will auto-refresh!"
echo ""
echo "Press Ctrl+C to stop development servers or run './scripts/stop-dev.sh'"

# Wait for user interrupt
wait