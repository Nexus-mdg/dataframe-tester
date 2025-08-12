# DataFrame Tester 🚀

![CI Status](https://github.com/Nexus-mdg/dataframe-tester/workflows/CI%20-%20DataFrame%20Tester/badge.svg)

A containerized DataFrame comparison and processing environment using Spark and Python. This project provides an easy-to-use platform for comparing, profiling, and manipulating CSV data files using Apache Spark.

## AI Code Disclaimer

⚠️ **AI-Generated Content Notice**: Portions of this codebase have been generated or assisted by artificial intelligence tools. While these components have been reviewed and tested, users should exercise appropriate caution and conduct their own validation when using this software in production environments.

🧪 **Testing Repository Notice**: This repository is intended for testing and experimental purposes only. It is not recommended for production use without thorough testing and validation in your specific environment.

## 🎯 What This Project Does

- **Compare DataFrames**: Find differences between CSV files
- **Profile Data**: Get statistics and insights about your datasets
- **Merge DataFrames**: Combine multiple CSV files based on common keys
- **Process at Scale**: Use Apache Spark for handling large datasets

## 📋 Prerequisites

Before you start, make sure you have:

- **Docker** (version 20.0 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Make** (usually pre-installed on Linux/Mac)
- **Git** (to clone this repository)

### 🔍 Check if you have the requirements:
```bash
docker --version
docker-compose --version
make --version
```

## 🚀 Quick Start (For Beginners)

### Step 1: Clone and Navigate
```bash
git clone <your-repo-url>
cd dataframe-tester
```

### Step 2: One-Command Setup
```bash
make setup
```
This single command will:
- Create all necessary directories
- Generate sample CSV files for testing
- Build Docker containers
- Start all services (Spark, Python runner)
- Wait for everything to be ready

### Step 3: Verify Everything Works
```bash
make test
```

### Step 4: Check Service Status
```bash
make status
```

🎉 **That's it!** Your environment is ready to use.

## 📖 Makefile Commands Reference

The Makefile provides simple commands to manage your environment. Just type `make <command>`:

### ❓ Getting Help
```bash
make help        # Show all available commands
```

### ⚙️ Setup & Management
```bash
make setup       # Complete setup (build + start + sample data)
make build       # Build Docker containers only
make start       # Start all services
make stop        # Stop all services
make restart     # Restart all services
```

### 📊 Check Status & Health
```bash
make status      # Show service status and available CSV files
make health      # Check if all services are responding
make logs        # View logs from all services
make logs-follow # Follow logs in real-time (Ctrl+C to exit)
```

### 🛠️ Development
```bash
make shell       # Open interactive shell in Python container
make test        # Run basic functionality tests
```

### 📊 DataFrame Operations

#### Compare Two CSV Files
```bash
make compare FILE1=data1.csv FILE2=data2.csv
```
**Example Output**: Shows differences between the files

#### Profile a Single CSV File
```bash
make profile FILE=data1.csv
```
**Example Output**: Statistics, column info, data types

#### Merge Two CSV Files
```bash
make merge FILE1=data1.csv FILE2=data2.csv KEY=id
```
**Example Output**: Combined dataset based on the specified key

#### List Available Functions
```bash
make list
```
**Example Output**: All available DataFrame operations

### 📁 File Management
```bash
make add-csv FILE=/path/to/your/file.csv  # Add your own CSV file to the project
```

### 🧹 Cleanup
```bash
make clean       # Stop services and remove containers
make clean-all   # Remove everything (containers, images, volumes)
```

## 🔗 Access Your Services

Once everything is running, you can access:

- **Spark Master UI**: http://localhost:8082

## 📁 Project Structure

```
dataframe-tester/
├── Makefile                 # All your commands
├── docker-compose.yml       # Service definitions
├── Dockerfile.python        # Python environment setup
├── setup.sh                 # Setup script (legacy)
├── data/                    # Your CSV files go here
│   ├── data1.csv           # Sample file 1
│   ├── data2.csv           # Sample file 2
│   └── data3.csv           # Sample file 3
└── scripts/                 # Python processing scripts
    ├── dataframe_processor.py
    ├── custom_functions.py
    └── function_template.py
```

## 💡 Common Use Cases

### Scenario 1: I have two CSV files and want to see differences
```bash
# Copy your files to the data/ directory
cp /path/to/your/file1.csv ./data/
cp /path/to/your/file2.csv ./data/

# Compare them
make compare FILE1=file1.csv FILE2=file2.csv
```

### Scenario 2: I want to understand my data better
```bash
make profile FILE=your-file.csv
```

### Scenario 3: I want to combine two datasets
```bash
make merge FILE1=customers.csv FILE2=orders.csv KEY=customer_id
```

### Scenario 4: Something isn't working
```bash
# Check if services are running
make health

# Look at logs for errors
make logs

# Restart everything
make restart
```

## 🔧 Troubleshooting

### Problem: "make: command not found"
**Solution**: Install make:
```bash
# Ubuntu/Debian
sudo apt-get install make

# MacOS
xcode-select --install
```

### Problem: "docker: command not found"
**Solution**: Install Docker from https://docs.docker.com/get-docker/

### Problem: Services won't start
**Solution**:
```bash
make clean       # Clean up
make setup       # Start fresh
```

### Problem: Can't access Spark UI
**Solution**: 
- Wait a bit longer (services take time to start)
- Check with `make health`
- Ensure port 8082 isn't used by other applications

### Problem: SparkFileNotFoundException when processing CSV files
**Solution**: This issue has been resolved in recent updates. The system now uses Spark in local mode to ensure proper file access within the containerized environment. If you encounter this error:
1. Make sure you're using the latest version of the code
2. Verify that your CSV files are in the `./data/` directory
3. Run `make restart` to refresh all services

## ⚡ Technical Details

### Spark Configuration
The DataFrame processor uses Apache Spark in **local mode** (`local[*]`) rather than distributed mode. This configuration:
- ✅ Ensures reliable file access within Docker containers
- ✅ Uses all available CPU cores for parallel processing  
- ✅ Simplifies deployment and reduces complexity
- ✅ Maintains high performance for typical data processing tasks

### Architecture Overview
- **Python Runner**: Executes DataFrame operations using PySpark
- **Spark Master**: Provides cluster coordination (optional for monitoring)
- **Spark Worker**: Provides additional compute capacity (optional)

## 🔄 Migrating from setup.sh

If you were using the old `setup.sh` script:

**Old way**:
```bash
./setup.sh
```

**New way**:
```bash
make setup
```

All the same functionality is available, but now it's organized into logical commands you can run independently.

## 🤝 Contributing

1. Add your custom functions to `scripts/custom_functions.py`
2. Test with `make test`
3. Submit a pull request

## ❓ Need Help?

1. Run `make help` to see all commands
2. Check the logs with `make logs`
3. Verify service health with `make health`
4. Open an issue in this repository

---

**Happy DataFrame Processing!** 🚀
