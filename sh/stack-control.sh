#!/bin/bash
# Stack Control Script for DataFrame Tester
# Manages Docker containers and services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to start the full stack
start_stack() {
    print_status "Starting DataFrame Tester stack..."

    cd "$PROJECT_DIR"

    # Create external network if it doesn't exist
    docker network create dataframe-tester_spark-net 2>/dev/null || true

    # Start Spark cluster first
    print_status "Starting Spark cluster..."
    docker compose -f docker-compose.spark.yml up -d

    # Wait for Spark master to be ready
    print_status "Waiting for Spark master to be ready..."
    sleep 10

    # Start main services
    print_status "Starting main services..."
    docker compose up -d

    print_success "Stack started successfully!"
    print_status "Services:"
    print_status "  - Spark Master UI: http://localhost:8082"
    print_status "  - DataFrame API: http://localhost:8651"
    print_status "  - Health Check: http://localhost:8651/health"
}

# Function to stop the full stack
stop_stack() {
    print_status "Stopping DataFrame Tester stack..."

    cd "$PROJECT_DIR"

    # Stop main services
    print_status "Stopping main services..."
    docker compose down

    # Stop Spark cluster
    print_status "Stopping Spark cluster..."
    docker compose -f docker-compose.spark.yml down

    print_success "Stack stopped successfully!"
}

# Function to restart the stack
restart_stack() {
    print_status "Restarting DataFrame Tester stack..."
    stop_stack
    sleep 5
    start_stack
}

# Function to show stack status
status_stack() {
    print_status "DataFrame Tester Stack Status:"
    echo ""

    cd "$PROJECT_DIR"

    # Check if containers are running
    echo "Container Status:"
    docker compose ps
    docker compose -f docker-compose.spark.yml ps

    echo ""
    echo "Network Status:"
    docker network ls | grep dataframe-tester || echo "No dataframe-tester networks found"

    echo ""
    echo "Volume Status:"
    docker volume ls | grep dataframe-tester || echo "No dataframe-tester volumes found"
}

# Function to view logs
logs_stack() {
    local service="$1"
    cd "$PROJECT_DIR"

    if [ -z "$service" ]; then
        print_status "Showing logs for all services..."
        docker compose logs -f
    else
        print_status "Showing logs for service: $service"
        docker compose logs -f "$service"
    fi
}

# Function to cleanup everything
cleanup_stack() {
    print_warning "This will remove all containers, volumes, and networks!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up DataFrame Tester stack..."

        cd "$PROJECT_DIR"

        # Stop and remove everything
        docker compose down -v --remove-orphans
        docker compose -f docker-compose.spark.yml down -v --remove-orphans

        # Remove network
        docker network rm dataframe-tester_spark-net 2>/dev/null || true

        # Remove images (optional)
        read -p "Remove built images as well? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose down --rmi all
            docker compose -f docker-compose.spark.yml down --rmi all
        fi

        print_success "Cleanup completed!"
    else
        print_status "Cleanup cancelled."
    fi
}

# Function to build images
build_stack() {
    print_status "Building DataFrame Tester images..."

    cd "$PROJECT_DIR"

    # Build main services
    docker compose build --no-cache

    print_success "Images built successfully!"
}

# Main script logic
case "$1" in
    start)
        start_stack
        ;;
    stop)
        stop_stack
        ;;
    restart)
        restart_stack
        ;;
    status)
        status_stack
        ;;
    logs)
        logs_stack "$2"
        ;;
    build)
        build_stack
        ;;
    cleanup)
        cleanup_stack
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs [service]|build|cleanup}"
        echo ""
        echo "Commands:"
        echo "  start    - Start the full DataFrame Tester stack"
        echo "  stop     - Stop the full DataFrame Tester stack"
        echo "  restart  - Restart the full DataFrame Tester stack"
        echo "  status   - Show status of all services"
        echo "  logs     - Show logs (optionally for specific service)"
        echo "  build    - Build all Docker images"
        echo "  cleanup  - Remove all containers, volumes, and networks"
        echo ""
        echo "Examples:"
        echo "  $0 start"
        echo "  $0 logs dataframe-api"
        echo "  $0 status"
        exit 1
        ;;
esac
