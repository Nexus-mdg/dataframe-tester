#!/usr/bin/env python3
"""
Health check script for all services
"""

import requests
import subprocess
import sys


def check_spark():
    """Check Spark Master health"""
    try:
        response = requests.get('http://spark-master:8080', timeout=5)
        return response.status_code == 200
    except:
        return False


def check_python_env():
    """Check Python environment"""
    try:
        import pyspark
        return True
    except ImportError:
        return False


def check_data_files():
    """Check if sample data files exist"""
    import os
    required_files = ['data1.csv', 'data2.csv']
    return all(os.path.exists(f'/app/data/{f}') for f in required_files)


def main():
    """Run all health checks"""
    checks = [
        ("Spark Master", check_spark),
        ("Python Environment", check_python_env),
        ("Data Files", check_data_files)
    ]

    all_healthy = True

    print("🔍 Running health checks...")

    for name, check_func in checks:
        try:
            if check_func():
                print(f"✅ {name}: OK")
            else:
                print(f"❌ {name}: FAILED")
                all_healthy = False
        except Exception as e:
            print(f"❌ {name}: ERROR - {e}")
            all_healthy = False

    if all_healthy:
        print("🎉 All services are healthy!")
        return 0
    else:
        print("⚠️  Some services are not healthy")
        return 1


if __name__ == "__main__":
    sys.exit(main())