#!/usr/bin/env python3
"""
Generalized DataFrame Processor
Supports pluggable functions for different DataFrame operations
Usage: python dataframe_processor.py <function_name> <file1.csv> [file2.csv] [file3.csv] ...
"""

import sys
import os
from pyspark.sql import SparkSession
from pyspark.sql.functions import *


def create_spark_session():
    """Create SparkSession"""
    spark = SparkSession.builder \
        .appName("DataFrameProcessor") \
        .master("local[*]")\
        .config("spark.executor.memory", "4g") \
        .config("spark.driver.memory", "4g") \
        .getOrCreate()
    return spark


def load_dataframes(spark, files):
    """Load multiple CSV files into Spark DataFrames"""
    dataframes = {}
    for file in files:
        try:
            df = spark.read.csv(f"/app/data/{file}", header=True, inferSchema=True)
            dataframes[file] = df
            print(f"✅ Loaded {file}: {df.count()} rows, {len(df.columns)} columns")
        except Exception as e:
            print(f"❌ Failed to load {file}: {e}")
            return None
    return dataframes


# =============================================================================
# PLUGGABLE FUNCTIONS - Add your custom functions here
# =============================================================================

def compare_dataframes(dataframes, *args):
    """Compare two DataFrames (default function)"""
    files = list(dataframes.keys())
    if len(files) != 2:
        return False, "Comparison requires exactly 2 files"

    df1, df2 = dataframes[files[0]], dataframes[files[1]]

    print(f"🔍 Comparing {files[0]} vs {files[1]}")

    # Schema comparison
    if df1.schema != df2.schema:
        return False, "Schemas differ"

    # Row count comparison
    count1, count2 = df1.count(), df2.count()
    if count1 != count2:
        return False, f"Row counts differ: {count1} vs {count2}"

    # Data comparison
    diff_count = df1.exceptAll(df2).count() + df2.exceptAll(df1).count()
    if diff_count > 0:
        return False, f"Data differs: {diff_count} differences found"

    return True, "DataFrames are identical!"


def merge_dataframes(dataframes, *args):
    """Merge multiple DataFrames on a common key"""
    files = list(dataframes.keys())
    if len(files) < 2:
        return False, "Merge requires at least 2 files"

    # Get join key from args or default to 'id'
    join_key = args[0] if args else 'id'
    print(f"🔗 Merging {len(files)} files on key: {join_key}")

    try:
        # Check if join key exists in all DataFrames
        for file, df in dataframes.items():
            if join_key not in df.columns:
                return False, f"Join key '{join_key}' not found in {file}"

        # Start with first DataFrame
        result = list(dataframes.values())[0]
        file_names = list(dataframes.keys())

        # Join with remaining DataFrames
        for i in range(1, len(dataframes)):
            df = list(dataframes.values())[i]
            result = result.join(df, on=join_key, how='inner')

        # Save merged result
        output_path = "/app/data/merged_result.csv"
        result.coalesce(1).write.mode('overwrite').option("header", "true").csv(output_path)

        final_count = result.count()
        return True, f"Merged {len(files)} files -> {final_count} rows saved to merged_result.csv"

    except Exception as e:
        return False, f"Merge failed: {e}"


def profile_dataframe(dataframes, *args):
    """Generate profile/summary statistics for DataFrames"""
    print(f"📊 Profiling {len(dataframes)} DataFrames...")

    results = []
    for file, df in dataframes.items():
        print(f"\n📄 Profile for {file}:")

        # Basic stats
        row_count = df.count()
        col_count = len(df.columns)
        print(f"   Rows: {row_count:,}, Columns: {col_count}")

        # Column info
        print(f"   Columns: {', '.join(df.columns)}")

        # Null counts
        null_counts = df.select([sum(col(c).isNull().cast("int")).alias(c) for c in df.columns]).collect()[0]
        null_info = {col: null_counts[col] for col in df.columns if null_counts[col] > 0}
        if null_info:
            print(f"   Nulls: {null_info}")

        # Numeric column stats
        numeric_cols = [field.name for field in df.schema.fields if
                        field.dataType.typeName() in ['integer', 'double', 'float', 'long']]
        if numeric_cols:
            stats = df.select(numeric_cols).summary().collect()
            print(f"   Numeric summaries available for: {', '.join(numeric_cols)}")

        results.append(f"{file}: {row_count} rows x {col_count} cols")

    return True, f"Profiled {len(dataframes)} files: " + ", ".join(results)


def validate_schema(dataframes, *args):
    """Validate that all DataFrames have the same schema"""
    files = list(dataframes.keys())
    if len(files) < 2:
        return False, "Schema validation requires at least 2 files"

    print(f"🔍 Validating schema consistency across {len(files)} files...")

    base_schema = list(dataframes.values())[0].schema
    base_file = files[0]

    for i, (file, df) in enumerate(list(dataframes.items())[1:], 1):
        if df.schema != base_schema:
            print(f"❌ Schema mismatch between {base_file} and {file}")
            print(f"   {base_file} columns: {[f.name for f in base_schema.fields]}")
            print(f"   {file} columns: {[f.name for f in df.schema.fields]}")
            return False, f"Schema validation failed: {base_file} vs {file}"

    return True, f"All {len(files)} files have identical schemas"


def aggregate_dataframe(dataframes, *args):
    """Aggregate DataFrame by specified columns"""
    files = list(dataframes.keys())
    if len(files) != 1:
        return False, "Aggregation works on exactly 1 file"

    df = list(dataframes.values())[0]
    file = files[0]

    # Get groupby columns and aggregation column from args
    if len(args) < 2:
        return False, "Usage: aggregate <file.csv> <group_col> <agg_col> [agg_func]"

    group_col = args[0]
    agg_col = args[1]
    agg_func = args[2] if len(args) > 2 else 'sum'

    print(f"📊 Aggregating {file} by {group_col}, {agg_func}({agg_col})")

    try:
        if agg_func == 'sum':
            result = df.groupBy(group_col).agg(sum(agg_col).alias(f"{agg_func}_{agg_col}"))
        elif agg_func == 'avg':
            result = df.groupBy(group_col).agg(avg(agg_col).alias(f"{agg_func}_{agg_col}"))
        elif agg_func == 'count':
            result = df.groupBy(group_col).count()
        elif agg_func == 'max':
            result = df.groupBy(group_col).agg(max(agg_col).alias(f"{agg_func}_{agg_col}"))
        elif agg_func == 'min':
            result = df.groupBy(group_col).agg(min(agg_col).alias(f"{agg_func}_{agg_col}"))
        else:
            return False, f"Unsupported aggregation function: {agg_func}"

        # Save result
        output_path = "/app/data/aggregated_result.csv"
        result.coalesce(1).write.mode('overwrite').option("header", "true").csv(output_path)

        result_count = result.count()
        return True, f"Aggregated {file} -> {result_count} groups saved to aggregated_result.csv"

    except Exception as e:
        return False, f"Aggregation failed: {e}"


# =============================================================================
# FUNCTION REGISTRY - Add new functions here
# =============================================================================

FUNCTIONS = {
    'compare': compare_dataframes,
    'merge': merge_dataframes,
    'profile': profile_dataframe,
    'validate': validate_schema,
    'aggregate': aggregate_dataframe,
}


def list_functions():
    """List all available functions"""
    print("📋 Available functions:")
    print("  compare    - Compare 2 DataFrames for equality")
    print("  merge      - Merge multiple DataFrames on common key")
    print("  profile    - Generate summary statistics")
    print("  validate   - Check schema consistency")
    print("  aggregate  - Group and aggregate data")
    print("")
    print("💡 Usage examples:")
    print("  python dataframe_processor.py compare data1.csv data2.csv")
    print("  python dataframe_processor.py merge data1.csv data2.csv data3.csv id")
    print("  python dataframe_processor.py profile data1.csv")
    print("  python dataframe_processor.py aggregate sales.csv region amount sum")


def main():
    """Main function with pluggable function support"""
    if len(sys.argv) < 2:
        print("Usage: python dataframe_processor.py <function_name> <file1.csv> [file2.csv] [args...]")
        print("")
        list_functions()
        sys.exit(1)

    if sys.argv[1] == 'list':
        list_functions()
        sys.exit(0)

    function_name = sys.argv[1]
    files = [arg for arg in sys.argv[2:] if arg.endswith('.csv')]
    extra_args = [arg for arg in sys.argv[2:] if not arg.endswith('.csv')]

    if function_name not in FUNCTIONS:
        print(f"❌ Unknown function: {function_name}")
        print(f"Available functions: {', '.join(FUNCTIONS.keys())}")
        sys.exit(1)

    if not files:
        print("❌ No CSV files provided")
        sys.exit(1)

    print(f"🚀 Running function: {function_name}")
    print(f"📁 Processing files: {', '.join(files)}")
    if extra_args:
        print(f"📋 Extra arguments: {', '.join(extra_args)}")

    spark = create_spark_session()

    try:
        # Load DataFrames
        dataframes = load_dataframes(spark, files)
        if dataframes is None:
            sys.exit(1)

        # Execute function
        func = FUNCTIONS[function_name]
        success, message = func(dataframes, *extra_args)

        if success:
            print(f"✅ SUCCESS: {message}")
            sys.exit(0)
        else:
            print(f"❌ FAILURE: {message}")
            sys.exit(1)

    except Exception as e:
        print(f"💥 UNEXPECTED ERROR: {e}")
        sys.exit(2)
    finally:
        spark.stop()


if __name__ == "__main__":
    main()