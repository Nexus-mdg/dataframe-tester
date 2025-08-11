#!/usr/bin/env python3
"""
Comprehensive API Testing Script for DataFrame Tester API
Tests all endpoints and functions with proper error handling
"""

import requests
import json
import os
import time

API_BASE_URL = "http://localhost:8651"
DATA_DIR = "/home/toavina/PycharmProjects/dataframe-tester/data"

def test_health_check():
    """Test the health check endpoint"""
    print("🔍 Testing Health Check...")
    response = requests.get(f"{API_BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_list_functions():
    """Test the functions listing endpoint"""
    print("\n📋 Testing Functions List...")
    response = requests.get(f"{API_BASE_URL}/api/functions")
    print(f"Status: {response.status_code}")
    data = response.json()
    print(f"Available functions: {len(data.get('functions', {}))}")
    for func, desc in data.get('functions', {}).items():
        print(f"  - {func}: {desc}")
    return response.status_code == 200

def test_single_file_functions():
    """Test functions that work with single files"""
    print("\n📊 Testing Single File Functions...")

    single_file_tests = [
        ("profile_dataframe", "Profile generation"),
        ("detect_anomalies", "Anomaly detection"),
        ("calculate_correlation", "Correlation calculation")
    ]

    results = []
    for func_name, description in single_file_tests:
        print(f"\n  Testing {description} ({func_name})...")
        try:
            with open(f"{DATA_DIR}/sample_data1.csv", "rb") as f:
                files = {"files": f}
                data = {"function": func_name}
                response = requests.post(f"{API_BASE_URL}/api/process", files=files, data=data)

            result = response.json()
            success = result.get("success", False)
            message = result.get("message", "No message")
            print(f"    Status: {response.status_code}, Success: {success}")
            print(f"    Message: {message}")

            results.append((func_name, success, response.status_code))

        except Exception as e:
            print(f"    Error: {e}")
            results.append((func_name, False, 500))

    return results

def test_multi_file_functions():
    """Test functions that work with multiple files"""
    print("\n📈 Testing Multi-File Functions...")

    multi_file_tests = [
        ("compare_dataframes", "DataFrame comparison"),
        ("validate_schema", "Schema validation"),
        ("merge_dataframes", "DataFrame merging", ["id"])  # with args
    ]

    results = []
    for test_data in multi_file_tests:
        func_name = test_data[0]
        description = test_data[1]
        args = test_data[2] if len(test_data) > 2 else []

        print(f"\n  Testing {description} ({func_name})...")
        try:
            with open(f"{DATA_DIR}/sample_data1.csv", "rb") as f1, \
                 open(f"{DATA_DIR}/sample_data2.csv", "rb") as f2:

                files = [("files", f1), ("files", f2)]
                data = {"function": func_name}
                if args:
                    data["args"] = ",".join(args)

                response = requests.post(f"{API_BASE_URL}/api/process", files=files, data=data)

            result = response.json()
            success = result.get("success", False)
            message = result.get("message", "No message")
            print(f"    Status: {response.status_code}, Success: {success}")
            print(f"    Message: {message}")

            results.append((func_name, success, response.status_code))

        except Exception as e:
            print(f"    Error: {e}")
            results.append((func_name, False, 500))

    return results

def test_error_handling():
    """Test various error conditions"""
    print("\n⚠️  Testing Error Handling...")

    # Test invalid function
    print("  Testing invalid function name...")
    try:
        with open(f"{DATA_DIR}/sample_data1.csv", "rb") as f:
            files = {"files": f}
            data = {"function": "invalid_function"}
            response = requests.post(f"{API_BASE_URL}/api/process", files=files, data=data)

        result = response.json()
        print(f"    Status: {response.status_code}")
        print(f"    Error message: {result.get('error', 'No error message')}")
    except Exception as e:
        print(f"    Error: {e}")

    # Test no files
    print("  Testing request with no files...")
    try:
        data = {"function": "profile_dataframe"}
        response = requests.post(f"{API_BASE_URL}/api/process", data=data)
        result = response.json()
        print(f"    Status: {response.status_code}")
        print(f"    Error message: {result.get('error', 'No error message')}")
    except Exception as e:
        print(f"    Error: {e}")

def test_concurrent_requests():
    """Test handling of concurrent requests"""
    print("\n🔄 Testing Concurrent Requests...")
    import threading
    import time

    results = []

    def make_request(request_id):
        try:
            with open(f"{DATA_DIR}/sample_data1.csv", "rb") as f:
                files = {"files": f}
                data = {"function": "profile_dataframe"}
                response = requests.post(f"{API_BASE_URL}/api/process", files=files, data=data)

            result = response.json()
            results.append((request_id, result.get("success", False), response.status_code))
            print(f"    Request {request_id}: Success={result.get('success', False)}")
        except Exception as e:
            results.append((request_id, False, 500))
            print(f"    Request {request_id}: Error={e}")

    # Start 3 concurrent requests
    threads = []
    for i in range(3):
        thread = threading.Thread(target=make_request, args=(i+1,))
        threads.append(thread)
        thread.start()

    # Wait for all to complete
    for thread in threads:
        thread.join()

    successful = sum(1 for _, success, _ in results if success)
    print(f"  Concurrent requests completed: {successful}/{len(results)} successful")

def main():
    """Run comprehensive API tests"""
    print("🚀 Starting Comprehensive API Testing...")
    print("=" * 60)

    # Wait a moment for the API to be ready
    time.sleep(2)

    try:
        # Basic endpoint tests
        health_ok = test_health_check()
        functions_ok = test_list_functions()

        if not health_ok:
            print("\n❌ Health check failed! API may not be running properly.")
            return

        # Function tests
        single_results = test_single_file_functions()
        multi_results = test_multi_file_functions()

        # Error handling tests
        test_error_handling()

        # Concurrent requests test
        test_concurrent_requests()

        # Summary
        print("\n" + "=" * 60)
        print("📊 TEST SUMMARY")
        print("=" * 60)

        print(f"Health Check: {'✅ PASS' if health_ok else '❌ FAIL'}")
        print(f"Functions List: {'✅ PASS' if functions_ok else '❌ FAIL'}")

        print("\nSingle File Functions:")
        for func, success, status in single_results:
            print(f"  {func}: {'✅ PASS' if success else '❌ FAIL'} (HTTP {status})")

        print("\nMulti-File Functions:")
        for func, success, status in multi_results:
            print(f"  {func}: {'✅ PASS' if success else '❌ FAIL'} (HTTP {status})")

        total_tests = len(single_results) + len(multi_results) + 2
        passed_tests = sum(1 for _, success, _ in single_results + multi_results if success) + (1 if health_ok else 0) + (1 if functions_ok else 0)

        print(f"\nOverall: {passed_tests}/{total_tests} tests passed ({passed_tests/total_tests*100:.1f}%)")

        if passed_tests == total_tests:
            print("🎉 All tests passed! API is working correctly.")
        else:
            print("⚠️  Some tests failed. Check the logs for details.")

    except Exception as e:
        print(f"\n❌ Test execution failed: {e}")

if __name__ == "__main__":
    main()
