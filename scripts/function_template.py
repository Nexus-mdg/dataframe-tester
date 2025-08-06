#!/usr/bin/env python3
"""
Template for creating custom DataFrame processing functions

Copy this template and modify it for your specific needs.
Then add your function to the FUNCTIONS dictionary in dataframe_processor.py
"""

from pyspark.sql.functions import *
from pyspark.sql.types import *


def template_function(dataframes, *args):
    """
    Template function for custom DataFrame operations

    Args:
        dataframes: Dictionary of {filename: spark_dataframe}
        *args: Additional arguments passed from command line

    Returns:
        tuple: (success: bool, message: str)
    """

    # 1. VALIDATE INPUTS
    files = list(dataframes.keys())

    # Example: Check number of files
    if len(files) != 2:  # Adjust based on your needs
        return False, "This function requires exactly 2 files"

    # Example: Check arguments
    if len(args) < 1:
        return False, "Usage: your_function <file1.csv> <file2.csv> <required_arg>"

    # 2. EXTRACT PARAMETERS
    # Get specific DataFrames
    df1 = dataframes[files[0]]
    df2 = dataframes[files[1]]

    # Get arguments
    required_arg = args[0]
    optional_arg = args[1] if len(args) > 1 else "default_value"

    # 3. VALIDATE DATA
    print(f"🔍 Processing {files[0]} and {files[1]} with arg: {required_arg}")

    # Example: Check if required columns exist
    required_columns = ['id', 'value']  # Adjust for your use case
    for file, df in dataframes.items():
        missing_cols = [col for col in required_columns if col not in df.columns]
        if missing_cols:
            return False, f"Missing columns in {file}: {missing_cols}"

    # 4. PROCESS DATA
    try:
        # Example processing logic - replace with your actual logic

        # Simple example: Join DataFrames
        if required_arg in df1.columns and required_arg in df2.columns:
            result = df1.join(df2, on=required_arg, how='inner')
        else:
            return False, f"Join column '{required_arg}' not found in both files"

        # Example: Add computed column
        result = result.withColumn("computed_value",
                                   col("value") * lit(2))  # Replace with your logic

        # Example: Filter data
        if optional_arg != "default_value":
            result = result.filter(col("computed_value") > lit(optional_arg))

        # 5. SAVE RESULTS (optional)
        output_path = "/app/data/template_result.csv"
        result.coalesce(1).write.mode('overwrite').option("header", "true").csv(output_path)

        # 6. CALCULATE METRICS
        result_count = result.count()
        result_cols = len(result.columns)

        # 7. RETURN SUCCESS
        return True, f"Processed {len(files)} files -> {result_count} rows x {result_cols} cols saved to template_result.csv"

    except Exception as e:
        # 8. HANDLE ERRORS
        return False, f"Processing failed: {str(e)}"


# Example of different function patterns:

def single_file_function(dataframes, *args):
    """Function that works on a single file"""
    files = list(dataframes.keys())
    if len(files) != 1:
        return False, "This function requires exactly 1 file"

    df = list(dataframes.values())[0]
    file = files[0]

    # Your single-file processing logic here
    try:
        # Example: Count rows
        row_count = df.count()
        return True, f"{file} has {row_count} rows"
    except Exception as e:
        return False, f"Failed to process {file}: {e}"


def multi_file_function(dataframes, *args):
    """Function that works on multiple files"""
    files = list(dataframes.keys())
    if len(files) < 2:
        return False, "This function requires at least 2 files"

    try:
        results = []
        for file, df in dataframes.items():
            # Process each DataFrame
            count = df.count()
            results.append(f"{file}: {count} rows")

        return True, " | ".join(results)
    except Exception as e:
        return False, f"Multi-file processing failed: {e}"


def aggregation_function(dataframes, *args):
    """Function that performs aggregation"""
    files = list(dataframes.keys())
    if len(files) != 1:
        return False, "Aggregation requires exactly 1 file"

    if len(args) < 2:
        return False, "Usage: aggregate_function <file.csv> <group_col> <agg_col> [agg_type]"

    df = list(dataframes.values())[0]
    group_col = args[0]
    agg_col = args[1]
    agg_type = args[2] if len(args) > 2 else 'sum'

    try:
        # Validate columns exist
        if group_col not in df.columns:
            return False, f"Group column '{group_col}' not found"
        if agg_col not in df.columns:
            return False, f"Aggregation column '{agg_col}' not found"

        # Perform aggregation
        if agg_type == 'sum':
            result = df.groupBy(group_col).agg(sum(agg_col).alias(f'sum_{agg_col}'))
        elif agg_type == 'avg':
            result = df.groupBy(group_col).agg(avg(agg_col).alias(f'avg_{agg_col}'))
        elif agg_type == 'count':
            result = df.groupBy(group_col).count()
        else:
            return False, f"Unsupported aggregation type: {agg_type}"

        # Save result
        output_path = "/app/data/aggregation_result.csv"
        result.coalesce(1).write.mode('overwrite').option("header", "true").csv(output_path)

        result_count = result.count()
        return True, f"Aggregated by '{group_col}' -> {result_count} groups saved"

    except Exception as e:
        return False, f"Aggregation failed: {e}"


"""
TO USE THESE TEMPLATES:

1. Copy the function you want to modify
2. Rename it to your desired function name
3. Modify the logic inside the try block
4. Add it to FUNCTIONS dictionary in dataframe_processor.py:

FUNCTIONS = {
    'compare': compare_dataframes,
    'merge': merge_dataframes,
    'your_function': your_custom_function,  # Add here
}

5. Test it:
docker exec python-runner python /app/scripts/dataframe_processor.py your_function data1.csv data2.csv arg1 arg2
"""