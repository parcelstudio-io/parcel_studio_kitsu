#!/bin/bash

# Stop Parcel Studio Kitsu Development Environment
echo "🛑 Stopping development environment..."

# Stop Kitsu frontend
if [ -f "src/kitsu/kitsu.pid" ]; then
    echo "Stopping Kitsu frontend..."
    kill $(cat src/kitsu/kitsu.pid) 2>/dev/null || echo "Kitsu frontend not running"
    rm -f src/kitsu/kitsu.pid
fi

# Stop Zou backend
if [ -f "zou-backend/zou/zou.pid" ]; then
    echo "Stopping Zou backend..."
    kill $(cat zou-backend/zou/zou.pid) 2>/dev/null || echo "Zou backend not running"
    rm -f zou-backend/zou/zou.pid
fi

# Stop development containers
echo "Stopping development databases..."
docker stop dev-postgres dev-redis 2>/dev/null || echo "Containers already stopped"
docker rm dev-postgres dev-redis 2>/dev/null || echo "Containers already removed"

echo "✅ Development environment stopped!"
echo ""
echo "To start again: ./scripts/build-dev.sh"