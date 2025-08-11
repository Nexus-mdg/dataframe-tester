#!/bin/bash
# Test Commands Script for DataFrame Tester
# Runs various tests and validations

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

# Function to run API tests
test_api() {
    print_status "Running API tests..."

    cd "$PROJECT_DIR"

    # Check if API is running
    if ! curl -s http://localhost:8651/health > /dev/null; then
        print_error "API is not running. Please start the stack first."
        return 1
    fi

    # Run the API test script
    python3 test_api.py

    print_success "API tests completed!"
}

# Function to run unit tests
test_unit() {
    print_status "Running unit tests..."

    cd "$PROJECT_DIR"

    # Run unit tests inside the python-runner container
    docker exec python-runner python -m pytest scripts/ -v

    print_success "Unit tests completed!"
}

# Function to run integration tests
test_integration() {
    print_status "Running integration tests..."

    cd "$PROJECT_DIR"

    # Test DataFrame processing functions
    docker exec python-runner python scripts/dataframe_processor.py

    # Test custom functions
    docker exec python-runner python scripts/custom_functions.py

    print_success "Integration tests completed!"
}

# Function to run performance tests
test_performance() {
    print_status "Running performance tests..."

    cd "$PROJECT_DIR"

    # Create test data if it doesn't exist
    if [ ! -f "data/large_test_data.csv" ]; then
        print_status "Generating large test dataset..."
        docker exec python-runner python -c "
import pandas as pd
import numpy as np

# Generate large dataset for performance testing
np.random.seed(42)
size = 100000
df = pd.DataFrame({
    'id': range(size),
    'value1': np.random.randn(size),
    'value2': np.random.randn(size),
    'category': np.random.choice(['A', 'B', 'C', 'D'], size),
    'timestamp': pd.date_range('2023-01-01', periods=size, freq='1min')
})
df.to_csv('/app/data/large_test_data.csv', index=False)
print('Large test dataset created!')
"
    fi

    # Run performance tests
    print_status "Testing large dataset processing..."
    time docker exec python-runner python -c "
import sys
sys.path.append('/app/scripts')
from dataframe_processor import create_spark_session, load_dataframes
import time

spark = create_spark_session()
start_time = time.time()
df = spark.read.csv('/app/data/large_test_data.csv', header=True, inferSchema=True)
df.count()  # Force evaluation
end_time = time.time()
print(f'Large dataset loaded and counted in {end_time - start_time:.2f} seconds')
"

    print_success "Performance tests completed!"
}

# Function to validate data quality
test_data_quality() {
    print_status "Running data quality tests..."

    cd "$PROJECT_DIR"

    # Check sample data files
    for file in data/sample_data*.csv; do
        if [ -f "$file" ]; then
            print_status "Validating $file..."
            docker exec python-runner python -c "
import sys
sys.path.append('/app/scripts')
from custom_functions import data_quality_check
from dataframe_processor import create_spark_session

spark = create_spark_session()
df = spark.read.csv('/app/$file', header=True, inferSchema=True)
result = data_quality_check(df)
print('Data quality check results:', result)
"
        fi
    done

    print_success "Data quality tests completed!"
}

# Function to test API endpoints comprehensively
test_api_comprehensive() {
    print_status "Running comprehensive API endpoint tests..."

    cd "$PROJECT_DIR"

    # Check if API is running
    if ! curl -s http://localhost:8651/health > /dev/null; then
        print_error "API is not running. Please start the stack first."
        return 1
    fi

    # Test health endpoint
    print_status "Testing /health endpoint..."
    curl -s http://localhost:8651/health | jq .

    # Test functions list endpoint
    print_status "Testing /functions endpoint..."
    curl -s http://localhost:8651/functions | jq .

    # Test file upload if sample data exists
    if [ -f "data/sample_data1.csv" ]; then
        print_status "Testing file upload endpoint..."
        curl -X POST -F "file=@data/sample_data1.csv" \
             http://localhost:8651/upload | jq .
    fi

    print_success "Comprehensive API tests completed!"
}

# Function to run all tests
test_all() {
    print_status "Running all tests..."

    test_api_comprehensive
    test_unit
    test_integration
    test_data_quality
    test_performance

    print_success "All tests completed!"
}

# Function to run smoke tests (quick validation)
test_smoke() {
    print_status "Running smoke tests..."

    cd "$PROJECT_DIR"

    # Check if containers are running
    if ! docker ps | grep -q "dataframe-api"; then
        print_error "dataframe-api container is not running"
        return 1
    fi

    if ! docker ps | grep -q "python-runner"; then
        print_error "python-runner container is not running"
        return 1
    fi

    if ! docker ps | grep -q "tester-spark-master"; then
        print_error "tester-spark-master container is not running"
        return 1
    fi

    # Quick API health check
    if curl -s http://localhost:8651/health | grep -q "healthy"; then
        print_success "API health check passed"
    else
        print_error "API health check failed"
        return 1
    fi

    print_success "Smoke tests passed!"
}

# Function to generate test report
test_report() {
    print_status "Generating test report..."

    cd "$PROJECT_DIR"

    REPORT_FILE="test_report_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "DataFrame Tester - Test Report"
        echo "Generated: $(date)"
        echo "================================"
        echo ""

        echo "Stack Status:"
        docker-compose ps
        echo ""

        echo "API Health Check:"
        curl -s http://localhost:8651/health 2>/dev/null || echo "API not responding"
        echo ""

        echo "Sample Data Files:"
        ls -la data/sample_data*.csv 2>/dev/null || echo "No sample data files found"
        echo ""

        echo "Recent Logs (last 20 lines):"
        docker-compose logs --tail=20 dataframe-api

    } > "$REPORT_FILE"

    print_success "Test report generated: $REPORT_FILE"
}

# Main script logic
case "$1" in
    api)
        test_api
        ;;
    unit)
        test_unit
        ;;
    integration)
        test_integration
        ;;
    performance)
        test_performance
        ;;
    quality)
        test_data_quality
        ;;
    comprehensive)
        test_api_comprehensive
        ;;
    all)
        test_all
        ;;
    smoke)
        test_smoke
        ;;
    report)
        test_report
        ;;
    *)
        echo "Usage: $0 {api|unit|integration|performance|quality|comprehensive|all|smoke|report}"
        echo ""
        echo "Commands:"
        echo "  api           - Run API tests using test_api.py"
        echo "  unit          - Run unit tests in containers"
        echo "  integration   - Run integration tests"
        echo "  performance   - Run performance tests with large datasets"
        echo "  quality       - Run data quality validation tests"
        echo "  comprehensive - Run comprehensive API endpoint tests"
        echo "  all           - Run all test suites"
        echo "  smoke         - Run quick smoke tests"
        echo "  report        - Generate a test report"
        echo ""
        echo "Examples:"
        echo "  $0 smoke      # Quick validation"
        echo "  $0 api        # Test API endpoints"
        echo "  $0 all        # Run everything"
        exit 1
        ;;
esac
