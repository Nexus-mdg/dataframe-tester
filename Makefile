# Makefile for DataFrame Tester Project
# On-demand Spark container management for efficient resource usage

.PHONY: help setup build start stop restart status clean test logs shell compare profile merge list health start-spark stop-spark spark-status

# Default target
help:
	@echo "🚀 DataFrame Tester - Available Commands"
	@echo ""
	@echo "Setup & Build:"
	@echo "  make setup     - Complete environment setup (Python runner only)"
	@echo "  make build     - Build Docker containers"
	@echo "  make start     - Start Python runner service"
	@echo "  make stop      - Stop all services"
	@echo "  make restart   - Restart all services"
	@echo ""
	@echo "Spark Management (On-Demand):"
	@echo "  make start-spark  - Start Spark cluster manually"
	@echo "  make stop-spark   - Stop Spark cluster"
	@echo "  make spark-status - Check Spark cluster status"
	@echo ""
	@echo "Status & Monitoring:"
	@echo "  make status    - Check service status"
	@echo "  make health    - Health check for all services"
	@echo "  make logs      - Show logs from all services"
	@echo "  make logs-follow - Follow logs in real-time"
	@echo ""
	@echo "Development:"
	@echo "  make shell     - Open shell in Python runner container"
	@echo "  make test      - Run basic functionality tests"
	@echo ""
	@echo "DataFrame Operations (Auto-start Spark):"
	@echo "  make compare FILE1=sample_data1.csv FILE2=sample_data2.csv - Compare two DataFrames"
	@echo "  make profile FILE=sample_data1.csv                         - Profile a DataFrame"
	@echo "  make merge FILE1=sample_data1.csv FILE2=sample_data2.csv KEY=id - Merge DataFrames"
	@echo "  make list                                    - List available functions"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean     - Stop services and remove containers"
	@echo "  make clean-all - Clean everything (containers, images, volumes)"
	@echo ""
	@echo "🔗 Access URLs:"
	@echo "  Spark UI: http://localhost:8082 (when Spark is running)"

# Setup commands
setup: create-dirs build start wait-for-services
	@echo "🎉 Setup complete! Python runner is ready."
	@echo "ℹ️  Spark will start automatically when you run DataFrame operations."
	@echo ""
	@$(MAKE) status

create-dirs:
	@echo "📁 Creating directory structure..."
	@mkdir -p data scripts

# Docker commands
build:
	@echo "🐳 Building containers..."
	@docker-compose build

start:
	@echo "🚀 Starting Python runner service..."
	@docker-compose up -d

stop:
	@echo "⏹️  Stopping all services..."
	@docker-compose stop
	@docker-compose -f docker-compose.spark.yml stop 2>/dev/null || true

restart: stop start

wait-for-services:
	@echo "⏳ Waiting for Python runner to start..."
	@sleep 10

# Spark management functions
start-spark:
	@echo "🔥 Starting Spark cluster..."
	@docker-compose -f docker-compose.spark.yml up -d --remove-orphans
	@echo "⏳ Waiting for Spark cluster to initialize..."
	@sleep 20
	@echo "✅ Spark cluster started! UI available at http://localhost:8082"

stop-spark:
	@echo "🔥 Stopping Spark cluster..."
	@docker-compose -f docker-compose.spark.yml stop

spark-status:
	@echo "🔍 Checking Spark cluster status..."
	@docker-compose -f docker-compose.spark.yml ps

# Internal helper to ensure Spark is running
_ensure-spark:
	@if ! docker ps --format "table {{.Names}}" | grep -q "tester-spark-master"; then \
		echo "🔥 Spark cluster not running, starting it..."; \
		$(MAKE) start-spark; \
	else \
		echo "✅ Spark cluster is already running"; \
	fi

# Internal helper to optionally stop Spark after operations
_cleanup-spark:
	@echo "💡 Tip: Run 'make stop-spark' to save resources when done with DataFrame operations"

# Status and monitoring
status:
	@echo "📊 Python Runner Status:"
	@docker-compose ps
	@echo ""
	@echo "📊 Spark Cluster Status:"
	@docker-compose -f docker-compose.spark.yml ps
	@echo ""
	@echo "📁 Available CSV files:"
	@ls -la data/*.csv 2>/dev/null || echo "No CSV files found in data/ directory"

health:
	@echo "🔍 Running system health checks..."
	@docker exec python-runner python /app/scripts/health_check.py || (echo "❌ Health checks failed" && exit 1)

logs:
	@docker-compose logs
	@docker-compose -f docker-compose.spark.yml logs

logs-follow:
	@docker-compose logs -f &
	@docker-compose -f docker-compose.spark.yml logs -f

# Development commands
shell:
	@echo "🐚 Opening shell in Python runner..."
	@docker exec -it python-runner /bin/bash

test: _ensure-spark
	@echo "🧪 Running basic functionality tests..."
	@echo "Testing list command:"
	@docker exec python-runner python /app/scripts/dataframe_processor.py list
	@echo ""
	@echo "Testing profile command:"
	@docker exec python-runner python /app/scripts/dataframe_processor.py profile sample_data1.csv
	@echo ""
	@echo "Testing compare command:"
	@docker exec python-runner python /app/scripts/dataframe_processor.py compare sample_data1.csv sample_data2.csv
	@$(MAKE) _cleanup-spark

# DataFrame operations with automatic Spark management
compare: _ensure-spark
	@if [ -z "$(FILE1)" ] || [ -z "$(FILE2)" ]; then \
		echo "❌ Error: Please specify FILE1 and FILE2"; \
		echo "Usage: make compare FILE1=sample_data1.csv FILE2=sample_data2.csv"; \
		exit 1; \
	fi
	@echo "🔍 Comparing $(FILE1) and $(FILE2)..."
	@docker exec python-runner python /app/scripts/dataframe_processor.py compare $(FILE1) $(FILE2)
	@$(MAKE) _cleanup-spark

profile: _ensure-spark
	@if [ -z "$(FILE)" ]; then \
		echo "❌ Error: Please specify FILE"; \
		echo "Usage: make profile FILE=sample_data1.csv"; \
		exit 1; \
	fi
	@echo "📊 Profiling $(FILE)..."
	@docker exec python-runner python /app/scripts/dataframe_processor.py profile $(FILE)
	@$(MAKE) _cleanup-spark

merge: _ensure-spark
	@if [ -z "$(FILE1)" ] || [ -z "$(FILE2)" ] || [ -z "$(KEY)" ]; then \
		echo "❌ Error: Please specify FILE1, FILE2, and KEY"; \
		echo "Usage: make merge FILE1=sample_data1.csv FILE2=sample_data2.csv KEY=id"; \
		exit 1; \
	fi
	@echo "🔗 Merging $(FILE1) and $(FILE2) on key $(KEY)..."
	@docker exec python-runner python /app/scripts/dataframe_processor.py merge $(FILE1) $(FILE2) $(KEY)
	@$(MAKE) _cleanup-spark

list:
	@echo "📋 Listing available functions..."
	@docker exec python-runner python /app/scripts/dataframe_processor.py list

# Cleanup commands
clean:
	@echo "🧹 Cleaning up containers..."
	@docker-compose down
	@docker-compose -f docker-compose.spark.yml down

clean-all:
	@echo "🧹 Cleaning everything (containers, images, volumes)..."
	@docker-compose down --rmi all --volumes --remove-orphans
	@docker-compose -f docker-compose.spark.yml down --rmi all --volumes --remove-orphans
	@docker system prune -f

# File operations
add-csv:
	@if [ -z "$(FILE)" ]; then \
		echo "❌ Error: Please specify FILE"; \
		echo "Usage: make add-csv FILE=/path/to/your/file.csv"; \
		exit 1; \
	fi
	@echo "📁 Copying $(FILE) to data/ directory..."
	@cp $(FILE) ./data/
	@echo "✅ File copied successfully"
	@$(MAKE) status

# Quick commands for common operations
quick-setup: setup
quick-test: start test
quick-clean: clean
