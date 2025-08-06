#!/bin/bash
# Complete setup script for containerized DataFrame comparison

set -e

echo "🚀 Setting up containerized DataFrame comparison environment..."

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p data scripts jenkins

# Create sample CSV files for testing
echo "📄 Creating sample CSV files..."
cat > data/data1.csv << EOF
id,name,value,date
1,Alice,100,2024-01-01
2,Bob,200,2024-01-02
3,Charlie,300,2024-01-03
EOF

cat > data/data2.csv << EOF
id,name,value,date
1,Alice,100,2024-01-01
2,Bob,200,2024-01-02
3,Charlie,300,2024-01-03
EOF

cat > data/data3.csv << EOF
id,name,value,date
1,Alice,150,2024-01-01
2,Bob,200,2024-01-02
3,Charlie,300,2024-01-03
EOF

# Copy Jenkinsfile to correct location
echo "📄 Setting up Jenkins files..."
cp jenkins/Jenkinsfile jenkins/

# Make scripts executable
chmod +x scripts/*.py scripts/*.sh 2>/dev/null || true

echo "🐳 Building and starting containers..."
docker-compose up -d --build

echo "⏳ Waiting for services to start..."
sleep 30

# Check services
echo "🔍 Checking service health..."

# Check Spark
if curl -s http://localhost:8080 > /dev/null; then
    echo "✅ Spark Master is running on http://localhost:8080"
else
    echo "⚠️  Spark Master may still be starting..."
fi

# Check Jenkins
if curl -s http://localhost:8585 > /dev/null; then
    echo "✅ Jenkins is running on http://localhost:8585"
else
    echo "⚠️  Jenkins may still be starting..."
fi

# Check Python Runner
if docker exec python-runner python --version > /dev/null 2>&1; then
    echo "✅ Python Runner is ready"
else
    echo "❌ Python Runner failed to start"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📊 Available CSV files in HOST ./data/ directory:"
ls -la data/*.csv
echo ""
echo "💡 How to add your CSV files:"
echo "   1. Copy your CSV files to ./data/ directory on your HOST machine"
echo "   2. Files will be automatically available in all containers"
echo "   3. Example: cp /path/to/your/file.csv ./data/"
echo ""
echo "📁 Directory mapping:"
echo "   HOST ./data/        -> CONTAINER /app/data/"
echo "   HOST ./scripts/     -> CONTAINER /app/scripts/"
echo "   HOST ./jenkins/     -> CONTAINER /var/jenkins_home/workspace/repo/"
echo ""
echo "🔗 Access URLs:"
echo "   Jenkins: http://localhost:8585"
echo "   Spark UI: http://localhost:8080"
echo ""
echo "💡 Test different functions manually:"
echo "   # Compare DataFrames (original functionality)"
echo "   docker exec python-runner python /app/scripts/dataframe_processor.py compare data1.csv data2.csv"
echo ""
echo "   # Profile DataFrames"
echo "   docker exec python-runner python /app/scripts/dataframe_processor.py profile data1.csv"
echo ""
echo "   # Merge DataFrames"
echo "   docker exec python-runner python /app/scripts/dataframe_processor.py merge data1.csv data2.csv id"
echo ""
echo "   # List all available functions"
echo "   docker exec python-runner python /app/scripts/dataframe_processor.py list"
echo ""
echo "🔧 To configure Jenkins:"
echo "   1. Go to http://localhost:8585"
echo "   2. Create a new Pipeline job"
echo "   3. Point to the Jenkinsfile in the repo"
echo "   4. Run with parameters: FILE1=data1.csv, FILE2=data2.csv"