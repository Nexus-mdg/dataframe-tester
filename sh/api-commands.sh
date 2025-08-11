#!/bin/bash
# REST API Commands Script for DataFrame Tester
# Provides convenient commands for interacting with the API

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default API configuration
API_BASE_URL="http://localhost:8651"
DATA_DIR="$PROJECT_DIR/data"

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

# Function to check if API is running
check_api() {
    if ! curl -s "$API_BASE_URL/health" > /dev/null; then
        print_error "API is not running at $API_BASE_URL"
        print_status "Please start the stack first: ./sh/stack-control.sh start"
        return 1
    fi
    return 0
}

# Function to get API health status
api_health() {
    print_status "Checking API health..."

    if check_api; then
        response=$(curl -s "$API_BASE_URL/health")
        echo "$response" | jq . 2>/dev/null || echo "$response"
        print_success "API is healthy!"
    fi
}

# Function to list available functions
api_functions() {
    print_status "Getting available functions..."

    if check_api; then
        response=$(curl -s "$API_BASE_URL/functions")
        echo "$response" | jq . 2>/dev/null || echo "$response"
    fi
}

# Function to upload a file
api_upload() {
    local file_path="$1"

    if [ -z "$file_path" ]; then
        print_error "Usage: $0 upload <file_path>"
        return 1
    fi

    if [ ! -f "$file_path" ]; then
        print_error "File not found: $file_path"
        return 1
    fi

    print_status "Uploading file: $file_path"

    if check_api; then
        response=$(curl -s -X POST -F "file=@$file_path" "$API_BASE_URL/upload")
        echo "$response" | jq . 2>/dev/null || echo "$response"

        if echo "$response" | grep -q "uploaded successfully"; then
            print_success "File uploaded successfully!"
        else
            print_error "Upload failed"
        fi
    fi
}

# Function to list uploaded files
api_list_files() {
    print_status "Getting list of uploaded files..."

    if check_api; then
        response=$(curl -s "$API_BASE_URL/files")
        echo "$response" | jq . 2>/dev/null || echo "$response"
    fi
}

# Function to compare two DataFrames
api_compare() {
    local file1="$1"
    local file2="$2"

    if [ -z "$file1" ] || [ -z "$file2" ]; then
        print_error "Usage: $0 compare <file1> <file2>"
        return 1
    fi

    print_status "Comparing DataFrames: $file1 vs $file2"

    if check_api; then
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"file1\": \"$file1\", \"file2\": \"$file2\"}" \
            "$API_BASE_URL/compare")

        echo "$response" | jq . 2>/dev/null || echo "$response"
    fi
}

# Function to merge DataFrames
api_merge() {
    local file1="$1"
    local file2="$2"
    local join_type="${3:-inner}"
    local join_keys="$4"

    if [ -z "$file1" ] || [ -z "$file2" ]; then
        print_error "Usage: $0 merge <file1> <file2> [join_type] [join_keys]"
        print_status "join_type: inner, outer, left, right (default: inner)"
        return 1
    fi

    print_status "Merging DataFrames: $file1 + $file2 (type: $join_type)"

    local payload="{\"file1\": \"$file1\", \"file2\": \"$file2\", \"join_type\": \"$join_type\""
    if [ -n "$join_keys" ]; then
        payload="$payload, \"join_keys\": [\"$join_keys\"]"
    fi
    payload="$payload}"

    if check_api; then
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$payload" \
            "$API_BASE_URL/merge")

        echo "$response" | jq . 2>/dev/null || echo "$response"
    fi
}

# Function to get DataFrame profile
api_profile() {
    local filename="$1"

    if [ -z "$filename" ]; then
        print_error "Usage: $0 profile <filename>"
        return 1
    fi

    print_status "Getting DataFrame profile: $filename"

    if check_api; then
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"filename\": \"$filename\"}" \
            "$API_BASE_URL/profile")

        echo "$response" | jq . 2>/dev/null || echo "$response"
    fi
}

# Function to validate DataFrame schema
api_validate() {
    local filename="$1"
    local schema="$2"

    if [ -z "$filename" ] || [ -z "$schema" ]; then
        print_error "Usage: $0 validate <filename> <schema_json>"
        print_status "Example schema: '{\"col1\": \"string\", \"col2\": \"integer\"}'"
        return 1
    fi

    print_status "Validating DataFrame schema: $filename"

    if check_api; then
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"filename\": \"$filename\", \"expected_schema\": $schema}" \
            "$API_BASE_URL/validate")

        echo "$response" | jq . 2>/dev/null || echo "$response"
    fi
}

# Function to aggregate DataFrame
api_aggregate() {
    local filename="$1"
    local group_columns="$2"
    local agg_functions="$3"

    if [ -z "$filename" ] || [ -z "$group_columns" ] || [ -z "$agg_functions" ]; then
        print_error "Usage: $0 aggregate <filename> <group_columns> <agg_functions>"
        print_status "Example: $0 aggregate data.csv 'category' '{\"value\": \"sum\", \"count\": \"count\"}'"
        return 1
    fi

    print_status "Aggregating DataFrame: $filename"

    if check_api; then
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"filename\": \"$filename\", \"group_columns\": [\"$group_columns\"], \"agg_functions\": $agg_functions}" \
            "$API_BASE_URL/aggregate")

        echo "$response" | jq . 2>/dev/null || echo "$response"
    fi
}

# Function to detect anomalies
api_anomalies() {
    local filename="$1"
    local columns="$2"

    if [ -z "$filename" ]; then
        print_error "Usage: $0 anomalies <filename> [columns]"
        return 1
    fi

    print_status "Detecting anomalies in: $filename"

    local payload="{\"filename\": \"$filename\""
    if [ -n "$columns" ]; then
        payload="$payload, \"columns\": [\"$columns\"]"
    fi
    payload="$payload}"

    if check_api; then
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$payload" \
            "$API_BASE_URL/detect_anomalies")

        echo "$response" | jq . 2>/dev/null || echo "$response"
    fi
}

# Function to perform data quality check
api_quality() {
    local filename="$1"

    if [ -z "$filename" ]; then
        print_error "Usage: $0 quality <filename>"
        return 1
    fi

    print_status "Checking data quality: $filename"

    if check_api; then
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"filename\": \"$filename\"}" \
            "$API_BASE_URL/data_quality")

        echo "$response" | jq . 2>/dev/null || echo "$response"
    fi
}

# Function to create pivot table
api_pivot() {
    local filename="$1"
    local index_col="$2"
    local columns_col="$3"
    local values_col="$4"

    if [ -z "$filename" ] || [ -z "$index_col" ] || [ -z "$columns_col" ] || [ -z "$values_col" ]; then
        print_error "Usage: $0 pivot <filename> <index_column> <columns_column> <values_column>"
        return 1
    fi

    print_status "Creating pivot table: $filename"

    if check_api; then
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"filename\": \"$filename\", \"index\": \"$index_col\", \"columns\": \"$columns_col\", \"values\": \"$values_col\"}" \
            "$API_BASE_URL/pivot")

        echo "$response" | jq . 2>/dev/null || echo "$response"
    fi
}

# Function to calculate correlation
api_correlation() {
    local filename="$1"
    local columns="$2"

    if [ -z "$filename" ]; then
        print_error "Usage: $0 correlation <filename> [columns]"
        return 1
    fi

    print_status "Calculating correlation: $filename"

    local payload="{\"filename\": \"$filename\""
    if [ -n "$columns" ]; then
        payload="$payload, \"columns\": [\"$columns\"]"
    fi
    payload="$payload}"

    if check_api; then
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$payload" \
            "$API_BASE_URL/correlation")

        echo "$response" | jq . 2>/dev/null || echo "$response"
    fi
}

# Function to download processed file
api_download() {
    local filename="$1"
    local output_path="${2:-./downloaded_$(basename $filename)}"

    if [ -z "$filename" ]; then
        print_error "Usage: $0 download <filename> [output_path]"
        return 1
    fi

    print_status "Downloading file: $filename to $output_path"

    if check_api; then
        curl -s "$API_BASE_URL/download/$filename" -o "$output_path"

        if [ -f "$output_path" ] && [ -s "$output_path" ]; then
            print_success "File downloaded: $output_path"
        else
            print_error "Download failed"
        fi
    fi
}

# Function to show API documentation
api_docs() {
    print_status "DataFrame Tester API Documentation"
    echo ""
    echo "Available Endpoints:"
    echo "  GET  /health              - API health check"
    echo "  GET  /functions           - List available functions"
    echo "  POST /upload              - Upload CSV file"
    echo "  GET  /files               - List uploaded files"
    echo "  POST /compare             - Compare two DataFrames"
    echo "  POST /merge               - Merge two DataFrames"
    echo "  POST /profile             - Get DataFrame profile"
    echo "  POST /validate            - Validate DataFrame schema"
    echo "  POST /aggregate           - Aggregate DataFrame"
    echo "  POST /detect_anomalies    - Detect anomalies"
    echo "  POST /data_quality        - Check data quality"
    echo "  POST /pivot               - Create pivot table"
    echo "  POST /correlation         - Calculate correlation"
    echo "  GET  /download/<filename> - Download processed file"
    echo ""
    echo "For detailed usage, see the script help or API source code."
}

# Function to run a quick demo
api_demo() {
    print_status "Running API demo with sample data..."

    if check_api; then
        # Upload sample file if it exists
        if [ -f "$DATA_DIR/sample_data1.csv" ]; then
            api_upload "$DATA_DIR/sample_data1.csv"
            echo ""

            api_profile "sample_data1.csv"
            echo ""

            api_quality "sample_data1.csv"
        else
            print_warning "No sample data found. Please add sample_data1.csv to $DATA_DIR"
        fi
    fi
}

# Main script logic
case "$1" in
    health)
        api_health
        ;;
    functions)
        api_functions
        ;;
    upload)
        api_upload "$2"
        ;;
    files)
        api_list_files
        ;;
    compare)
        api_compare "$2" "$3"
        ;;
    merge)
        api_merge "$2" "$3" "$4" "$5"
        ;;
    profile)
        api_profile "$2"
        ;;
    validate)
        api_validate "$2" "$3"
        ;;
    aggregate)
        api_aggregate "$2" "$3" "$4"
        ;;
    anomalies)
        api_anomalies "$2" "$3"
        ;;
    quality)
        api_quality "$2"
        ;;
    pivot)
        api_pivot "$2" "$3" "$4" "$5"
        ;;
    correlation)
        api_correlation "$2" "$3"
        ;;
    download)
        api_download "$2" "$3"
        ;;
    docs)
        api_docs
        ;;
    demo)
        api_demo
        ;;
    *)
        echo "Usage: $0 {command} [arguments]"
        echo ""
        echo "Commands:"
        echo "  health                                    - Check API health"
        echo "  functions                                 - List available functions"
        echo "  upload <file>                            - Upload CSV file"
        echo "  files                                    - List uploaded files"
        echo "  compare <file1> <file2>                  - Compare two DataFrames"
        echo "  merge <file1> <file2> [type] [keys]      - Merge DataFrames"
        echo "  profile <file>                           - Get DataFrame profile"
        echo "  validate <file> <schema_json>            - Validate schema"
        echo "  aggregate <file> <group_col> <agg_json>  - Aggregate DataFrame"
        echo "  anomalies <file> [columns]               - Detect anomalies"
        echo "  quality <file>                           - Check data quality"
        echo "  pivot <file> <index> <cols> <values>     - Create pivot table"
        echo "  correlation <file> [columns]             - Calculate correlation"
        echo "  download <file> [output_path]            - Download file"
        echo "  docs                                     - Show API documentation"
        echo "  demo                                     - Run quick demo"
        echo ""
        echo "Examples:"
        echo "  $0 health"
        echo "  $0 upload data/sample.csv"
        echo "  $0 profile sample.csv"
        echo "  $0 compare file1.csv file2.csv"
        exit 1
        ;;
esac
