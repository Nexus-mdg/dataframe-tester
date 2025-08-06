#!/usr/bin/env python3
"""
Example custom functions that can be added to dataframe_processor.py
Copy these functions into the PLUGGABLE FUNCTIONS section of dataframe_processor.py
"""

from pyspark.sql.functions import *
from pyspark.sql.types import *


def detect_anomalies(dataframes, *args):
    """Detect anomalies in numeric columns using statistical methods"""
    files = list(dataframes.keys())
    if len(files) != 1:
        return False, "Anomaly detection works on exactly 1 file"

    df = list(dataframes.values())[0]
    file = files[0]

    # Get numeric columns
    numeric_cols = [field.name for field in df.schema.fields
                    if field.dataType.typeName() in ['integer', 'double', 'float', 'long']]

    if not numeric_cols:
        return False, "No numeric columns found for anomaly detection"

    # Get column to analyze (from args or use first numeric column)
    target_col = args[0] if args and args[0] in numeric_cols else numeric_cols[0]

    print(f"🔍 Detecting anomalies in column '{target_col}' from {file}")

    try:
        # Calculate statistics
        stats = df.select(
            mean(col(target_col)).alias('mean'),
            stddev(col(target_col)).alias('stddev')
        ).collect()[0]

        mean_val = stats['mean']
        std_val = stats['stddev']

        # Define anomalies as values beyond 2 standard deviations
        threshold = 2
        lower_bound = mean_val - (threshold * std_val)
        upper_bound = mean_val + (threshold * std_val)

        # Find anomalies
        anomalies = df.filter(
            (col(target_col) < lower_bound) | (col(target_col) > upper_bound)
        )

        anomaly_count = anomalies.count()
        total_count = df.count()

        if anomaly_count > 0:
            # Save anomalies
            output_path = "/app/data/anomalies_detected.csv"
            anomalies.coalesce(1).write.mode('overwrite').option("header", "true").csv(output_path)

        percentage = (anomaly_count / total_count) * 100 if total_count > 0 else 0

        return True, f"Found {anomaly_count}/{total_count} anomalies ({percentage:.1f}%) in '{target_col}'"

    except Exception as e:
        return False, f"Anomaly detection failed: {e}"


def data_quality_check(dataframes, *args):
    """Comprehensive data quality assessment"""
    results = []

    for file, df in dataframes.items():
        print(f"🔍 Quality check for {file}")

        total_rows = df.count()
        total_cols = len(df.columns)

        quality_issues = []

        # Check for null values
        null_counts = df.select([sum(col(c).isNull().cast("int")).alias(c) for c in df.columns]).collect()[0]
        null_cols = [(col, null_counts[col]) for col in df.columns if null_counts[col] > 0]

        if null_cols:
            quality_issues.append(f"Null values in {len(null_cols)} columns")

        # Check for duplicate rows
        distinct_rows = df.distinct().count()
        duplicates = total_rows - distinct_rows
        if duplicates > 0:
            quality_issues.append(f"{duplicates} duplicate rows")

        # Check for empty strings in string columns
        string_cols = [field.name for field in df.schema.fields if field.dataType.typeName() == 'string']
        empty_string_issues = []
        for col_name in string_cols:
            empty_count = df.filter((col(col_name) == "") | (col(col_name).isNull())).count()
            if empty_count > 0:
                empty_string_issues.append(f"{col_name}: {empty_count}")

        if empty_string_issues:
            quality_issues.append(f"Empty strings: {', '.join(empty_string_issues)}")

        # Calculate quality score
        total_cells = total_rows * total_cols
        null_cells = sum(null_counts[col] for col in df.columns)
        quality_score = ((total_cells - null_cells) / total_cells) * 100 if total_cells > 0 else 0

        result = f"{file}: {quality_score:.1f}% quality"
        if quality_issues:
            result += f" (Issues: {'; '.join(quality_issues)})"
        else:
            result += " (No issues found)"

        results.append(result)
        print(f"   Quality Score: {quality_score:.1f}%")
        if quality_issues:
            print(f"   Issues: {'; '.join(quality_issues)}")

    return True, " | ".join(results)


def pivot_dataframe(dataframes, *args):
    """Pivot DataFrame on specified columns"""
    files = list(dataframes.keys())
    if len(files) != 1:
        return False, "Pivot works on exactly 1 file"

    if len(args) < 3:
        return False, "Usage: pivot <file.csv> <index_col> <pivot_col> <value_col>"

    df = list(dataframes.values())[0]
    file = files[0]
    index_col, pivot_col, value_col = args[0], args[1], args[2]

    print(f"🔄 Pivoting {file}: index={index_col}, pivot={pivot_col}, values={value_col}")

    try:
        # Perform pivot
        pivoted = df.groupBy(index_col).pivot(pivot_col).sum(value_col)

        # Save result
        output_path = "/app/data/pivoted_result.csv"
        pivoted.coalesce(1).write.mode('overwrite').option("header", "true").csv(output_path)

        result_count = pivoted.count()
        result_cols = len(pivoted.columns)

        return True, f"Pivoted {file} -> {result_count} rows x {result_cols} cols saved to pivoted_result.csv"

    except Exception as e:
        return False, f"Pivot failed: {e}"


def calculate_correlation(dataframes, *args):
    """Calculate correlation matrix for numeric columns"""
    files = list(dataframes.keys())
    if len(files) != 1:
        return False, "Correlation calculation works on exactly 1 file"

    df = list(dataframes.values())[0]
    file = files[0]

    # Get numeric columns
    numeric_cols = [field.name for field in df.schema.fields
                    if field.dataType.typeName() in ['integer', 'double', 'float', 'long']]

    if len(numeric_cols) < 2:
        return False, "Need at least 2 numeric columns for correlation"

    print(f"📊 Calculating correlations for {file}: {', '.join(numeric_cols)}")

    try:
        correlations = []

        for i, col1 in enumerate(numeric_cols):
            for col2 in numeric_cols[i + 1:]:
                corr_value = df.stat.corr(col1, col2)
                correlations.append(f"{col1}-{col2}: {corr_value:.3f}")

        # Create correlation summary
        correlation_summary = "; ".join(correlations)

        return True, f"Correlations calculated: {correlation_summary}"

    except Exception as e:
        return False, f"Correlation calculation failed: {e}"


# Add these functions to FUNCTIONS dictionary in dataframe_processor.py:
"""
'anomalies': detect_anomalies,
'quality': data_quality_check,
'pivot': pivot_dataframe,
'correlation': calculate_correlation,
"""