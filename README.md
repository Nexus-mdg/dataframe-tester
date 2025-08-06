# DataFrame Tester 🚀

A containerized DataFrame comparison and processing environment using Spark, Jenkins, and Python. This project provides an easy-to-use platform for comparing, profiling, and manipulating CSV data files using Apache Spark.

## 🎯 What This Project Does

- **Compare DataFrames**: Find differences between CSV files
- **Profile Data**: Get statistics and insights about your datasets
- **Merge DataFrames**: Combine multiple CSV files based on common keys
- **Process at Scale**: Use Apache Spark for handling large datasets
- **CI/CD Integration**: Jenkins pipeline for automated testing

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
- Start all services (Spark, Jenkins, Python runner)
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

### 🆘 Getting Help
```bash
make help        # Show all available commands
```

### 🏗️ Setup & Management
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

### 🔧 Development
```bash
make shell       # Open interactive shell in Python container
make test        # Run basic functionality tests
```

### 📈 DataFrame Operations

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

## 🌐 Access Your Services

Once everything is running, you can access:

- **Spark Master UI**: http://localhost:8080
- **Jenkins**: http://localhost:8585

## 🎯 Using Jenkins Pipeline (NEW!)

The project now includes a Jenkins pipeline that allows you to execute DataFrame operations through a web interface. This is perfect for team collaboration and automated workflows.

### 🚀 How to Use Jenkins Pipeline

1. **Access Jenkins**: Go to http://localhost:8585
2. **Find the Pipeline**: Look for your DataFrame processing pipeline job
3. **Click "Build with Parameters"**: This opens the parameter form
4. **Fill in the Parameters**:
   - **FUNCTION**: Choose the operation (compare, profile, merge, etc.)
   - **FILES**: List CSV files separated by commas (e.g., `data1.csv,data2.csv`)
   - **ARGS**: Additional arguments if needed (e.g., column names for merge operations)

### 📝 Jenkins Pipeline Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `FUNCTION` | The DataFrame operation to perform | `compare`, `profile`, `merge`, `list` |
| `FILES` | CSV files to process (comma-separated) | `data1.csv,data2.csv` |
| `ARGS` | Additional arguments for the function | `id` (for merge key) |

### 💡 Jenkins Pipeline Examples

#### Example 1: Compare Two Files
- **FUNCTION**: `compare`
- **FILES**: `data1.csv,data2.csv`
- **ARGS**: (leave empty)

#### Example 2: Profile a Single File
- **FUNCTION**: `profile`
- **FILES**: `data1.csv`
- **ARGS**: (leave empty)

#### Example 3: Merge Files on a Key
- **FUNCTION**: `merge`
- **FILES**: `data1.csv,data2.csv`
- **ARGS**: `id`

#### Example 4: List Available Functions
- **FUNCTION**: `list`
- **FILES**: (leave empty)
- **ARGS**: (leave empty)

### 🔍 Pipeline Features

- **File Validation**: The pipeline checks that all specified CSV files exist before execution
- **Error Handling**: Clear success/failure messages with detailed logging
- **Command Preview**: Shows the exact command being executed
- **Status Tracking**: Visual indicators (✅ success, ❌ failure) throughout execution

### 🎭 Jenkins vs Make Commands

You can use either Jenkins (web interface) or Make (command line) for the same operations:

| Operation | Jenkins Parameters | Make Command |
|-----------|-------------------|--------------|
| Compare files | FUNCTION=`compare`, FILES=`data1.csv,data2.csv` | `make compare FILE1=data1.csv FILE2=data2.csv` |
| Profile data | FUNCTION=`profile`, FILES=`data1.csv` | `make profile FILE=data1.csv` |
| Merge files | FUNCTION=`merge`, FILES=`data1.csv,data2.csv`, ARGS=`id` | `make merge FILE1=data1.csv FILE2=data2.csv KEY=id` |
| List functions | FUNCTION=`list` | `make list` |

### 🔄 Jenkins Workflow Benefits

- **Team Collaboration**: Non-technical team members can run operations through the web UI
- **Audit Trail**: Jenkins keeps logs of all executions with timestamps
- **Scheduled Jobs**: Can be configured to run automatically
- **Parameter Validation**: Jenkins validates inputs before execution
- **Integration Ready**: Easy to integrate with other CI/CD workflows

## 📁 Project Structure

```
dataframe-tester/
├── Makefile                 # All your commands (NEW!)
├── docker-compose.yml       # Service definitions
├── Dockerfile.python        # Python environment setup
├── setup.sh                 # Original setup script (legacy)
├── data/                    # Your CSV files go here
│   ├── data1.csv           # Sample file 1
│   ├── data2.csv           # Sample file 2
│   └── data3.csv           # Sample file 3
├── scripts/                 # Python processing scripts
│   ├── dataframe_processor.py
│   ├── custom_functions.py
│   └── function_template.py
└── jenkins/                 # CI/CD configuration
    └── Jenkinsfile
```

## 💡 Common Use Cases

### 🔍 Scenario 1: I have two CSV files and want to see differences
```bash
# Copy your files to the data/ directory
cp /path/to/your/file1.csv ./data/
cp /path/to/your/file2.csv ./data/

# Compare them
make compare FILE1=file1.csv FILE2=file2.csv
```

### 📊 Scenario 2: I want to understand my data better
```bash
make profile FILE=your-file.csv
```

### 🔗 Scenario 3: I want to combine two datasets
```bash
make merge FILE1=customers.csv FILE2=orders.csv KEY=customer_id
```

### 🐛 Scenario 4: Something isn't working
```bash
# Check if services are running
make health

# Look at logs for errors
make logs

# Restart everything
make restart
```

## 🆘 Troubleshooting

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

### Problem: Can't access Spark UI or Jenkins
**Solution**: 
- Wait a bit longer (services take time to start)
- Check with `make health`
- Ensure ports 8080 and 8585 aren't used by other applications

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

**Happy DataFrame Processing!** 🎉
