# Jenkins Pipeline Guide 🚀

A comprehensive guide to using Jenkins for DataFrame testing and operations in the DataFrame Tester project.

## 📋 Table of Contents

- [What is Jenkins Pipeline?](#what-is-jenkins-pipeline)
- [Quick Start](#quick-start)
- [Setting Up Jenkins Pipeline](#setting-up-jenkins-pipeline)
- [Using the Pipeline](#using-the-pipeline)
- [Pipeline Parameters](#pipeline-parameters)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## 🎯 What is Jenkins Pipeline?

Jenkins Pipeline provides a **web-based interface** for running DataFrame operations that would normally be executed via command line. This is perfect for:

- **Team Collaboration**: Non-technical team members can run tests
- **Audit Trail**: Keep logs of all executions with timestamps
- **Scheduled Jobs**: Run operations automatically on a schedule
- **Parameter Validation**: Web form validates inputs before execution
- **Visual Feedback**: Clear success/failure indicators

## 🚀 Quick Start

### Prerequisites
Make sure your environment is running:
```bash
make setup    # If not already done
make status   # Verify services are running
```

### Access Jenkins
1. Open your browser and go to: **http://localhost:8788**
2. Jenkins should be accessible (may take a few minutes to start up)

## 🛠️ Setting Up Jenkins Pipeline

Since Jenkins doesn't automatically detect the pipeline, you need to create it manually:

### Step 1: Create New Pipeline Job

1. **Access Jenkins**: Go to http://localhost:8788
2. **Click "New Item"** (on the left sidebar)
3. **Enter Job Name**: `DataFrame-Tester-Pipeline` (or any name you prefer)
4. **Select "Pipeline"** from the project types
5. **Click "OK"**

### Step 2: Configure the Pipeline

1. **In the job configuration page**:
   - Scroll down to the **"Pipeline"** section
   - Set **Definition** to: `Pipeline script from SCM`
   - Set **SCM** to: `None` (we'll use a local file)

2. **Alternative: Direct Script Method**:
   - Set **Definition** to: `Pipeline script`
   - Copy the entire content from `jenkins/Jenkinsfile` into the script box

3. **Using File Path Method** (Recommended):
   - Set **Definition** to: `Pipeline script from SCM`
   - Set **SCM** to: `Git` 
   - **Repository URL**: Leave empty or use `.` for local
   - **Script Path**: `jenkins/Jenkinsfile`

### Step 3: Save Configuration

1. **Click "Save"** at the bottom of the page
2. You'll be redirected to the job's main page

## 🎮 Using the Pipeline

### Running Your First Test

1. **From the job page, click "Build with Parameters"**
2. **You'll see three parameter fields**:
   - **FUNCTION**: Dropdown with available operations
   - **FILES**: Text field for CSV filenames
   - **ARGS**: Text field for additional arguments

3. **For your first test, try the "list" function**:
   - **FUNCTION**: Select `list`
   - **FILES**: Leave empty (not needed for list)
   - **ARGS**: Leave empty
   - **Click "Build"**

4. **Watch the execution**:
   - Click on the build number (e.g., "#1") in the build history
   - Click "Console Output" to see real-time logs

## 📝 Pipeline Parameters

| Parameter | Required | Description | Examples |
|-----------|----------|-------------|----------|
| **FUNCTION** | ✅ Yes | The DataFrame operation to perform | `list`, `compare`, `profile`, `merge` |
| **FILES** | ⚠️ Depends on function | CSV files (comma-separated) | `sample_data1.csv,sample_data2.csv` |
| **ARGS** | ❌ Optional | Additional function arguments | `id` (for merge key) |

### Function-Specific Requirements:

| Function | FILES Required? | ARGS Usage | Example |
|----------|----------------|------------|---------|
| `list` | ❌ No | Not used | FILES: (empty), ARGS: (empty) |
| `profile` | ✅ Yes (1 file) | Not used | FILES: `sample_data1.csv`, ARGS: (empty) |
| `compare` | ✅ Yes (2 files) | Not used | FILES: `sample_data1.csv,sample_data2.csv`, ARGS: (empty) |
| `merge` | ✅ Yes (2 files) | ✅ Required (merge key) | FILES: `sample_data1.csv,sample_data2.csv`, ARGS: `id` |

## 💡 Examples

### Example 1: List Available Functions
**Purpose**: See what operations are available
```
FUNCTION: list
FILES: (leave empty)
ARGS: (leave empty)
```

### Example 2: Profile a Dataset
**Purpose**: Get statistics about a single CSV file
```
FUNCTION: profile
FILES: sample_data1.csv
ARGS: (leave empty)
```

### Example 3: Compare Two Files
**Purpose**: Find differences between two CSV files
```
FUNCTION: compare
FILES: sample_data1.csv,sample_data2.csv
ARGS: (leave empty)
```

### Example 4: Merge Two Datasets
**Purpose**: Combine two CSV files using a common column
```
FUNCTION: merge
FILES: sample_data1.csv,sample_data2.csv
ARGS: id
```

### Example 5: Using Your Own Files
**Purpose**: Work with your own CSV files
```bash
# First, add your file to the data directory
make add-csv FILE=/path/to/your/file.csv

# Then use it in Jenkins:
FUNCTION: profile
FILES: your-file.csv
ARGS: (leave empty)
```

## 🔍 Understanding Pipeline Execution

### Pipeline Stages

The Jenkins pipeline runs through these stages:

1. **🔍 Health Check**
   - Verifies Python runner container is accessible
   - Checks Spark Master (non-blocking)
   - Ensures the environment is ready

2. **📁 Validate Files** (skipped for `list` function)
   - Checks that all specified CSV files exist
   - Validates file paths and accessibility
   - Fails early if files are missing

3. **⚡ Execute Function**
   - Builds the command dynamically
   - Executes the DataFrame operation
   - Captures output and status

### Reading the Output

**✅ Success Indicators:**
- Green checkmarks in the stage view
- "Function executed successfully!" message
- Detailed operation results in console output

**❌ Failure Indicators:**
- Red X marks in the stage view
- Clear error messages explaining what went wrong
- Troubleshooting tips in the failure section

## 🆘 Troubleshooting

### Problem: "Build with Parameters" not showing
**Solution**: 
- Make sure you created a **Pipeline** job (not Freestyle)
- Verify the Jenkinsfile contains the `parameters` block
- Try refreshing the job configuration

### Problem: "File not found" errors
**Solution**:
```bash
# Check what files are available
make status

# Add missing files
make add-csv FILE=/path/to/your/file.csv

# Verify files are in the right place
ls -la data/
```

### Problem: "Python Runner is not accessible"
**Solution**:
```bash
# Check container status
make status

# Restart services if needed
make restart

# Wait for services to fully start
sleep 30
```

### Problem: Pipeline job not found or 404 error
**Solution**:
- Verify Jenkins is running: http://localhost:8788
- Check that you created the pipeline job correctly
- Make sure the job name matches what you're trying to access

### Problem: "Permission denied" errors
**Solution**:
```bash
# Fix file permissions
sudo chown -R $USER:$USER ./data/
sudo chmod -R 755 ./data/
```

### Problem: Long execution times
**Explanation**: This is normal for:
- Large CSV files (>100MB)
- Complex merge operations
- First-time container startup

## 🚀 Advanced Usage

### Scheduling Automatic Runs

1. **In the job configuration**:
   - Check "Build periodically"
   - Use cron syntax: `H 2 * * *` (runs daily at 2 AM)

### Creating Multiple Pipeline Jobs

You can create specialized pipeline jobs for different use cases:

- **Daily-Comparison-Job**: Automatically compares yesterday's data with today's
- **Weekly-Profile-Job**: Generates weekly data profiles
- **Data-Validation-Job**: Runs validation checks on uploaded files

### Integration with Other Tools

The Jenkins pipeline can be extended to:
- Send email notifications on completion
- Upload results to cloud storage
- Trigger downstream jobs based on results
- Integrate with monitoring systems

### Custom Jenkinsfile Modifications

You can modify `jenkins/Jenkinsfile` to:
- Add new function choices
- Implement custom validation rules
- Add notification steps
- Create environment-specific configurations

## 📊 Jenkins vs Command Line Comparison

| Aspect | Jenkins Pipeline | Command Line (`make`) |
|--------|------------------|----------------------|
| **Ease of Use** | ✅ Web interface, user-friendly | ⚠️ Requires terminal knowledge |
| **Team Access** | ✅ Anyone can access via browser | ❌ Requires system access |
| **Audit Trail** | ✅ Full execution history | ❌ No built-in logging |
| **Parameter Validation** | ✅ Web form validation | ⚠️ Manual validation |
| **Scheduling** | ✅ Built-in cron scheduling | ⚠️ Requires external cron setup |
| **Speed** | ⚠️ Slight overhead | ✅ Direct execution |
| **Troubleshooting** | ✅ Visual stage indicators | ⚠️ Text-based output only |

## 🎯 Best Practices

### For Regular Users:
1. **Start with `list`** to understand available functions
2. **Use `profile`** to explore new datasets before comparison
3. **Keep file names simple** (no spaces, special characters)
4. **Check build history** to see previous successful parameters

### For Administrators:
1. **Backup Jenkins configuration** regularly
2. **Monitor disk space** in the data directory
3. **Review build history** periodically to clean up old builds
4. **Set up notifications** for failed builds

### For Developers:
1. **Test Jenkinsfile changes** in a separate job first
2. **Use descriptive commit messages** when updating the pipeline
3. **Document custom modifications** in this guide
4. **Keep the pipeline simple** and focused on DataFrame operations

## 🔗 Quick Reference Links

- **Jenkins Web UI**: http://localhost:8788
- **Spark Master UI**: http://localhost:8082
- **Project Documentation**: [README.md](README.md)
- **Makefile Commands**: Run `make help`

## 📞 Getting Help

1. **Check Jenkins console output** for detailed error messages
2. **Run equivalent make command** to compare results:
   ```bash
   # If Jenkins fails, try the equivalent make command:
   make compare FILE1=data1.csv FILE2=data2.csv
   ```
3. **Verify environment health**:
   ```bash
   make health
   make status
   ```
4. **Review this guide** for common solutions
5. **Check the main README.md** for additional troubleshooting

---

**Happy Pipeline Testing!** 🎉

> 💡 **Pro Tip**: Bookmark this guide and the Jenkins web interface for quick access during your DataFrame processing workflow.
