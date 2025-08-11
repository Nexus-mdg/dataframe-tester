#!/bin/bash

# Build and start the complete DataFrame Tester stack with UI

echo "🚀 Starting DataFrame Tester with UI..."

# Build all services
echo "📦 Building services..."
docker-compose build

# Start all services
echo "🌟 Starting services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check service status
echo "🔍 Checking service status..."
echo "API Service:"
curl -s http://localhost:8651/health | jq . || echo "API not ready yet"

echo -e "\n📊 DataFrame Tester is running!"
echo "🌐 UI: http://localhost:3000"
echo "🔧 API: http://localhost:8651"
echo "📋 API Health: http://localhost:8651/health"
echo "📖 API Functions: http://localhost:8651/api/functions"

echo -e "\n🛑 To stop all services: docker-compose down"
