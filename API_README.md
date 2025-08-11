# DataFrame Tester REST API

A powerful REST API for DataFrame operations built with Flask and Apache Spark. This service provides HTTP endpoints for DataFrame processing, comparison, merging, profiling, and advanced analytics.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- `jq` (optional, for JSON formatting)
- `curl` (for API calls)

### Starting the API

```bash
# Start the full stack
make start

# Or using the script directly
./sh/stack-control.sh start

# Check API health
curl http://localhost:8651/health
```

The API will be available at `http://localhost:8651`

## 📋 API Endpoints

### Health & Information

#### Check API Health
```bash
GET /health
```

**Example:**
```bash
curl http://localhost:8651/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "spark_status": "connected"
}
```

#### List Available Functions
```bash
GET /functions
```

**Example:**
```bash
curl http://localhost:8651/functions | jq
```

### File Operations

#### Upload CSV File
```bash
POST /upload
Content-Type: multipart/form-data
```

**Example:**
```bash
curl -X POST -F "file=@data/sample_data1.csv" http://localhost:8651/upload
```

**Response:**
```json
{
  "message": "File uploaded successfully",
  "filename": "sample_data1.csv",
  "size": 1024,
  "upload_time": "2024-01-15T10:30:00Z"
}
```

#### List Uploaded Files
```bash
GET /files
```

**Example:**
```bash
curl http://localhost:8651/files | jq
```

#### Download Processed File
```bash
GET /download/<filename>
```

**Example:**
```bash
curl http://localhost:8651/download/processed_data.csv -o downloaded_file.csv
```

### DataFrame Operations

#### Compare DataFrames
```bash
POST /compare
Content-Type: application/json
```

**Payload:**
```json
{
  "file1": "sample_data1.csv",
  "file2": "sample_data2.csv"
}
```

**Example:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"file1": "sample_data1.csv", "file2": "sample_data2.csv"}' \
  http://localhost:8651/compare | jq
```

**Response:**
```json
{
  "comparison_result": {
    "rows_df1": 1000,
    "rows_df2": 950,
    "columns_df1": 5,
    "columns_df2": 5,
    "schema_match": true,
    "differences": [
      {
        "type": "missing_rows",
        "count": 50,
        "details": "50 rows missing in file2"
      }
    ]
  },
  "execution_time": "2.34s"
}
```

#### Merge DataFrames
```bash
POST /merge
Content-Type: application/json
```

**Payload:**
```json
{
  "file1": "sample_data1.csv",
  "file2": "sample_data2.csv",
  "join_type": "inner",
  "join_keys": ["id"]
}
```

**Example:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "file1": "sample_data1.csv",
    "file2": "sample_data2.csv",
    "join_type": "inner",
    "join_keys": ["id"]
  }' \
  http://localhost:8651/merge | jq
```

**Join Types:**
- `inner` - Inner join (default)
- `outer` - Full outer join
- `left` - Left outer join
- `right` - Right outer join

#### Profile DataFrame
```bash
POST /profile
Content-Type: application/json
```

**Payload:**
```json
{
  "filename": "sample_data1.csv"
}
```

**Example:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"filename": "sample_data1.csv"}' \
  http://localhost:8651/profile | jq
```

**Response:**
```json
{
  "profile": {
    "total_rows": 1000,
    "total_columns": 5,
    "columns": {
      "id": {
        "type": "integer",
        "null_count": 0,
        "unique_count": 1000,
        "min": 1,
        "max": 1000
      },
      "name": {
        "type": "string",
        "null_count": 5,
        "unique_count": 995
      },
      "value": {
        "type": "double",
        "null_count": 2,
        "mean": 45.67,
        "std": 12.34,
        "min": 10.5,
        "max": 99.8
      }
    }
  }
}
```

#### Validate Schema
```bash
POST /validate
Content-Type: application/json
```

**Payload:**
```json
{
  "filename": "sample_data1.csv",
  "expected_schema": {
    "id": "integer",
    "name": "string",
    "value": "double",
    "category": "string",
    "timestamp": "timestamp"
  }
}
```

**Example:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "filename": "sample_data1.csv",
    "expected_schema": {
      "id": "integer",
      "name": "string",
      "value": "double"
    }
  }' \
  http://localhost:8651/validate | jq
```

#### Aggregate DataFrame
```bash
POST /aggregate
Content-Type: application/json
```

**Payload:**
```json
{
  "filename": "sample_data1.csv",
  "group_columns": ["category"],
  "agg_functions": {
    "value": "sum",
    "id": "count"
  }
}
```

**Example:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "filename": "sample_data1.csv",
    "group_columns": ["category"],
    "agg_functions": {
      "value": "sum",
      "id": "count"
    }
  }' \
  http://localhost:8651/aggregate | jq
```

### Advanced Analytics

#### Detect Anomalies
```bash
POST /detect_anomalies
Content-Type: application/json
```

**Payload:**
```json
{
  "filename": "sample_data1.csv",
  "columns": ["value", "score"]
}
```

**Example:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "filename": "sample_data1.csv",
    "columns": ["value"]
  }' \
  http://localhost:8651/detect_anomalies | jq
```

#### Data Quality Check
```bash
POST /data_quality
Content-Type: application/json
```

**Payload:**
```json
{
  "filename": "sample_data1.csv"
}
```

**Example:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"filename": "sample_data1.csv"}' \
  http://localhost:8651/data_quality | jq
```

**Response:**
```json
{
  "quality_report": {
    "completeness": 0.98,
    "null_percentage": 0.02,
    "duplicate_rows": 5,
    "data_types_consistency": true,
    "outliers_detected": 12,
    "recommendations": [
      "Consider handling 5 duplicate rows",
      "Investigate 12 potential outliers in 'value' column"
    ]
  }
}
```

#### Create Pivot Table
```bash
POST /pivot
Content-Type: application/json
```

**Payload:**
```json
{
  "filename": "sample_data1.csv",
  "index": "category",
  "columns": "month",
  "values": "value"
}
```

**Example:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "filename": "sample_data1.csv",
    "index": "category",
    "columns": "month",
    "values": "value"
  }' \
  http://localhost:8651/pivot | jq
```

#### Calculate Correlation
```bash
POST /correlation
Content-Type: application/json
```

**Payload:**
```json
{
  "filename": "sample_data1.csv",
  "columns": ["value1", "value2", "score"]
}
```

**Example:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "filename": "sample_data1.csv",
    "columns": ["value1", "value2"]
  }' \
  http://localhost:8651/correlation | jq
```

## 🛠 Using the API Scripts

The project includes convenient bash scripts for interacting with the API:

### Basic API Commands

```bash
# Check API health
./sh/api-commands.sh health

# List available functions
./sh/api-commands.sh functions

# Upload a file
./sh/api-commands.sh upload data/sample_data1.csv

# List uploaded files
./sh/api-commands.sh files
```

### DataFrame Operations

```bash
# Compare two files
./sh/api-commands.sh compare sample_data1.csv sample_data2.csv

# Merge files with inner join
./sh/api-commands.sh merge sample_data1.csv sample_data2.csv inner id

# Profile a DataFrame
./sh/api-commands.sh profile sample_data1.csv

# Check data quality
./sh/api-commands.sh quality sample_data1.csv
```

### Advanced Analytics

```bash
# Detect anomalies
./sh/api-commands.sh anomalies sample_data1.csv value

# Calculate correlation
./sh/api-commands.sh correlation sample_data1.csv value1,value2

# Create pivot table
./sh/api-commands.sh pivot sample_data1.csv category month value
```

### Using Makefile Commands

```bash
# API health check
make api-health

# List functions
make api-functions

# Run API demo
make api-demo

# Show API documentation
make api-docs
```

## 📊 Example Workflows

### Complete Data Processing Workflow

```bash
# 1. Start the API
make start

# 2. Upload your data files
curl -X POST -F "file=@sales_data.csv" http://localhost:8651/upload
curl -X POST -F "file=@customer_data.csv" http://localhost:8651/upload

# 3. Profile the datasets
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"filename": "sales_data.csv"}' \
  http://localhost:8651/profile

# 4. Check data quality
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"filename": "sales_data.csv"}' \
  http://localhost:8651/data_quality

# 5. Merge datasets
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "file1": "sales_data.csv",
    "file2": "customer_data.csv",
    "join_type": "left",
    "join_keys": ["customer_id"]
  }' \
  http://localhost:8651/merge

# 6. Create analytics
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "filename": "merged_result.csv",
    "group_columns": ["region"],
    "agg_functions": {"sales": "sum", "orders": "count"}
  }' \
  http://localhost:8651/aggregate
```

### Data Quality Assessment

```bash
# Upload file
./sh/api-commands.sh upload data/suspicious_data.csv

# Check data quality
./sh/api-commands.sh quality suspicious_data.csv

# Detect anomalies
./sh/api-commands.sh anomalies suspicious_data.csv amount

# Calculate correlations to understand relationships
./sh/api-commands.sh correlation suspicious_data.csv amount,score,rating
```

## 🔧 Configuration

### Environment Variables

- `SPARK_MASTER_URL`: Spark master URL (default: `spark://tester-spark-master:7077`)
- `FLASK_ENV`: Flask environment (default: `production`)
- `FLASK_DEBUG`: Flask debug mode (default: `0`)

### File Limits

- Maximum file size: 200MB
- Supported formats: CSV
- Upload directory: `/app/data/uploads`
- Output directory: `/app/data/outputs`

## 🚦 Error Handling

### Common Error Responses

#### File Not Found
```json
{
  "error": "File not found",
  "message": "The specified file 'nonexistent.csv' was not found",
  "code": 404
}
```

#### Invalid JSON
```json
{
  "error": "Invalid JSON",
  "message": "Request body must be valid JSON",
  "code": 400
}
```

#### Processing Error
```json
{
  "error": "Processing failed",
  "message": "DataFrame operation failed: Column 'invalid_column' not found",
  "code": 500
}
```

## 📈 Performance Tips

1. **Large Files**: For files > 50MB, consider splitting them or using the performance test endpoints
2. **Memory**: Monitor Spark UI at `http://localhost:8082` for memory usage
3. **Caching**: Frequently accessed files are cached in Spark memory
4. **Parallel Processing**: The API can handle multiple concurrent requests

## 🔍 Monitoring

### Health Monitoring

```bash
# Check overall health
curl http://localhost:8651/health

# Monitor with watch
watch -n 5 'curl -s http://localhost:8651/health | jq'
```

### Logs

```bash
# View API logs
make logs

# Follow logs in real-time
docker logs -f dataframe-api

# View Spark logs
docker logs -f tester-spark-master
```

## 🐛 Troubleshooting

### API Not Responding
```bash
# Check if containers are running
make status

# Restart the stack
make restart

# Check logs for errors
make logs
```

### Spark Connection Issues
```bash
# Verify Spark cluster
docker ps | grep spark

# Check Spark UI
curl http://localhost:8082

# Restart Spark cluster
./sh/stack-control.sh stop
./sh/stack-control.sh start
```

### File Upload Issues
```bash
# Check file permissions
ls -la data/

# Verify file size (< 200MB)
du -h your_file.csv

# Check disk space
df -h
```

## 📚 Additional Resources

- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new endpoints
4. Update this documentation
5. Submit a pull request

---

**Need help?** Check the logs with `make logs` or run `make api-docs` for quick reference.
