#!/usr/bin/env python3
"""
Flask REST API for DataFrame Operations
Provides HTTP endpoints for DataFrame processing functions
"""

import os
import uuid
import tempfile
from flask import Flask, request, jsonify, send_file
from werkzeug.utils import secure_filename
from werkzeug.exceptions import RequestEntityTooLarge
import sys
import traceback
import shutil
from datetime import datetime

# Import our existing DataFrame processor functions
sys.path.append('/app/scripts')
from dataframe_processor import (
    create_spark_session, load_dataframes, compare_dataframes,
    merge_dataframes, profile_dataframe, validate_schema, aggregate_dataframe
)
from custom_functions import (
    detect_anomalies, data_quality_check, pivot_dataframe, calculate_correlation
)

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 200 * 1024 * 1024  # 200MB max file size
app.config['UPLOAD_FOLDER'] = '/app/data/uploads'
app.config['OUTPUT_FOLDER'] = '/app/data/outputs'

# Ensure upload and output directories exist
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
os.makedirs(app.config['OUTPUT_FOLDER'], exist_ok=True)

# Global Spark session
spark = None

def get_spark_session():
    """Get or create Spark session"""
    global spark
    if spark is None:
        spark = create_spark_session()
    return spark

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in {'csv'}

def cleanup_temp_files(file_paths):
    """Clean up temporary uploaded files"""
    for file_path in file_paths:
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
        except Exception as e:
            print(f"Warning: Could not remove temp file {file_path}: {e}")

@app.errorhandler(RequestEntityTooLarge)
def handle_file_too_large(error):
    return jsonify({
        'success': False,
        'error': 'File too large. Maximum size is 200MB.'
    }), 413

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'spark_session': spark is not None
    })

@app.route('/api/functions', methods=['GET'])
def list_functions():
    """List available DataFrame processing functions"""
    functions = {
        'compare_dataframes': 'Compare two DataFrames for equality',
        'merge_dataframes': 'Merge multiple DataFrames on a common key',
        'profile_dataframe': 'Generate profile/summary statistics for DataFrames',
        'validate_schema': 'Validate that all DataFrames have the same schema',
        'aggregate_dataframe': 'Aggregate DataFrames with grouping and aggregation functions',
        'detect_anomalies': 'Detect anomalies in numeric columns',
        'data_quality_check': 'Perform comprehensive data quality checks',
        'pivot_dataframe': 'Pivot DataFrames on specified columns',
        'calculate_correlation': 'Calculate correlation matrix for numeric columns'
    }
    return jsonify({
        'success': True,
        'functions': functions
    })

@app.route('/api/process', methods=['POST'])
def process_dataframes():
    """Main endpoint for processing DataFrames"""
    try:
        # Get function name from form data
        function_name = request.form.get('function')
        if not function_name:
            return jsonify({
                'success': False,
                'error': 'function parameter is required'
            }), 400

        # Get optional arguments
        args = []
        if 'args' in request.form:
            args = request.form.get('args').split(',')
            args = [arg.strip() for arg in args if arg.strip()]

        # Check if files were uploaded
        if 'files' not in request.files:
            return jsonify({
                'success': False,
                'error': 'No files uploaded'
            }), 400

        files = request.files.getlist('files')
        if not files or all(file.filename == '' for file in files):
            return jsonify({
                'success': False,
                'error': 'No files selected'
            }), 400

        # Validate function exists
        function_map = {
            'compare_dataframes': compare_dataframes,
            'merge_dataframes': merge_dataframes,
            'profile_dataframe': profile_dataframe,
            'validate_schema': validate_schema,
            'aggregate_dataframe': aggregate_dataframe,
            'detect_anomalies': detect_anomalies,
            'data_quality_check': data_quality_check,
            'pivot_dataframe': pivot_dataframe,
            'calculate_correlation': calculate_correlation
        }

        if function_name not in function_map:
            return jsonify({
                'success': False,
                'error': f'Unknown function: {function_name}. Available functions: {list(function_map.keys())}'
            }), 400

        # Create unique session ID for this request
        session_id = str(uuid.uuid4())
        session_folder = os.path.join(app.config['UPLOAD_FOLDER'], session_id)
        os.makedirs(session_folder, exist_ok=True)

        # Save uploaded files
        uploaded_files = []
        temp_file_paths = []

        for file in files:
            if file and file.filename and allowed_file(file.filename):
                filename = secure_filename(file.filename)
                file_path = os.path.join(session_folder, filename)
                file.save(file_path)
                uploaded_files.append(filename)
                temp_file_paths.append(file_path)
            else:
                # Clean up and return error
                shutil.rmtree(session_folder, ignore_errors=True)
                return jsonify({
                    'success': False,
                    'error': f'Invalid file: {file.filename}. Only CSV files are allowed.'
                }), 400

        if not uploaded_files:
            shutil.rmtree(session_folder, ignore_errors=True)
            return jsonify({
                'success': False,
                'error': 'No valid CSV files uploaded'
            }), 400

        # Get Spark session and load DataFrames
        spark_session = get_spark_session()

        # Temporarily change data path for this session
        original_data_path = "/app/data"
        temp_data_path = session_folder

        # Create temporary symlinks or copy files to expected location
        temp_links = []
        for filename in uploaded_files:
            src = os.path.join(session_folder, filename)
            dst = os.path.join(original_data_path, filename)
            if not os.path.exists(dst):
                os.symlink(src, dst)
                temp_links.append(dst)

        try:
            # Load DataFrames using the existing function
            dataframes = load_dataframes(spark_session, uploaded_files)

            if dataframes is None:
                return jsonify({
                    'success': False,
                    'error': 'Failed to load one or more DataFrames'
                }), 400

            # Execute the requested function
            func = function_map[function_name]
            success, message = func(dataframes, *args)

            # Check if there are any output files to return
            output_files = []
            output_dir = "/app/data"
            potential_outputs = ['merged_result.csv', 'anomalies_result.csv', 'quality_report.csv',
                                'pivot_result.csv', 'correlation_result.csv', 'aggregated_result.csv']

            for output_file in potential_outputs:
                output_path = os.path.join(output_dir, output_file)
                if os.path.exists(output_path):
                    # Move to session-specific output folder
                    session_output_dir = os.path.join(app.config['OUTPUT_FOLDER'], session_id)
                    os.makedirs(session_output_dir, exist_ok=True)
                    new_path = os.path.join(session_output_dir, output_file)
                    shutil.move(output_path, new_path)
                    output_files.append({
                        'filename': output_file,
                        'download_url': f'/api/download/{session_id}/{output_file}'
                    })

            response = {
                'success': success,
                'message': message,
                'function': function_name,
                'files_processed': uploaded_files,
                'session_id': session_id,
                'output_files': output_files
            }

            return jsonify(response)

        finally:
            # Clean up temporary symlinks
            for link in temp_links:
                try:
                    if os.path.islink(link):
                        os.unlink(link)
                except Exception as e:
                    print(f"Warning: Could not remove symlink {link}: {e}")

            # Clean up uploaded files
            shutil.rmtree(session_folder, ignore_errors=True)

    except Exception as e:
        print(f"Error processing request: {e}")
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': f'Internal server error: {str(e)}'
        }), 500

@app.route('/api/download/<session_id>/<filename>', methods=['GET'])
def download_file(session_id, filename):
    """Download output files"""
    try:
        file_path = os.path.join(app.config['OUTPUT_FOLDER'], session_id, filename)
        if not os.path.exists(file_path):
            return jsonify({
                'success': False,
                'error': 'File not found'
            }), 404

        return send_file(file_path, as_attachment=True, download_name=filename)

    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Error downloading file: {str(e)}'
        }), 500

@app.route('/api/sessions/<session_id>/cleanup', methods=['DELETE'])
def cleanup_session(session_id):
    """Clean up session files"""
    try:
        session_output_dir = os.path.join(app.config['OUTPUT_FOLDER'], session_id)
        if os.path.exists(session_output_dir):
            shutil.rmtree(session_output_dir)

        return jsonify({
            'success': True,
            'message': f'Session {session_id} cleaned up'
        })

    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Error cleaning up session: {str(e)}'
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
