# DataFrame Tester Makefile
# Uses bash scripts in sh/ directory for organized command management

.PHONY: help start stop restart status logs build cleanup test test-all test-smoke test-api test-unit test-integration test-performance test-quality test-report api-health api-functions api-demo api-docs

# Default target
help:
	@echo "DataFrame Tester - Available Commands"
	@echo "===================================="
	@echo ""
	@echo "Stack Control:"
	@echo "  make start      - Start the full DataFrame Tester stack"
	@echo "  make stop       - Stop the full DataFrame Tester stack"
	@echo "  make restart    - Restart the full DataFrame Tester stack"
	@echo "  make status     - Show status of all services"
	@echo "  make logs       - Show logs for all services"
	@echo "  make build      - Build all Docker images"
	@echo "  make cleanup    - Clean up containers, volumes, and networks"
	@echo ""
	@echo "Testing:"
	@echo "  make test-all   - Run all test suites"
	@echo "  make test-smoke - Run quick smoke tests"
	@echo "  make test-api   - Run API tests"
	@echo "  make test-unit  - Run unit tests"
	@echo "  make test-integration - Run integration tests"
	@echo "  make test-performance - Run performance tests"
	@echo "  make test-quality     - Run data quality tests"
	@echo "  make test-report      - Generate test report"
	@echo ""
	@echo "API Commands:"
	@echo "  make api-health - Check API health"
	@echo "  make api-functions - List available API functions"
	@echo "  make api-demo   - Run API demo with sample data"
	@echo "  make api-docs   - Show API documentation"
	@echo ""
	@echo "Direct script access:"
	@echo "  ./sh/stack-control.sh {start|stop|restart|status|logs|build|cleanup}"
	@echo "  ./sh/test-commands.sh {api|unit|integration|performance|quality|all|smoke|report}"
	@echo "  ./sh/api-commands.sh {health|functions|upload|compare|merge|profile|...}"

# Stack Control Commands
start:
	@./sh/stack-control.sh start

stop:
	@./sh/stack-control.sh stop

restart:
	@./sh/stack-control.sh restart

status:
	@./sh/stack-control.sh status

logs:
	@./sh/stack-control.sh logs

build:
	@./sh/stack-control.sh build

cleanup:
	@./sh/stack-control.sh cleanup

# Testing Commands
test-all:
	@./sh/test-commands.sh all

test-smoke:
	@./sh/test-commands.sh smoke

test-api:
	@./sh/test-commands.sh api

test-unit:
	@./sh/test-commands.sh unit

test-integration:
	@./sh/test-commands.sh integration

test-performance:
	@./sh/test-commands.sh performance

test-quality:
	@./sh/test-commands.sh quality

test-report:
	@./sh/test-commands.sh report

# Legacy test command (equivalent to former make test)
test:
	@echo "🧪 Running basic functionality tests..."
	@echo "Testing list command:"
	@docker exec python-runner python /app/scripts/dataframe_processor.py list
	@echo ""
	@echo "Testing profile command:"
	@docker exec python-runner python /app/scripts/dataframe_processor.py profile sample_data1.csv
	@echo ""
	@echo "Testing compare command:"
	@docker exec python-runner python /app/scripts/dataframe_processor.py compare sample_data1.csv sample_data2.csv

# API Commands
api-health:
	@./sh/api-commands.sh health

api-functions:
	@./sh/api-commands.sh functions

api-demo:
	@./sh/api-commands.sh demo

api-docs:
	@./sh/api-commands.sh docs

# Development workflow shortcuts
dev-start: build start
	@echo "Development environment started!"
	@echo "API: http://localhost:8651"
	@echo "Spark UI: http://localhost:8082"

dev-test: test-smoke test-api
	@echo "Development tests completed!"

dev-reset: stop cleanup start
	@echo "Development environment reset!"
