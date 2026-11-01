#!/usr/bin/env python3
"""Run all meteogalicia tests (i18n validation, air quality tests, and forecast tests)."""

import os
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent


def main():
    env = {**os.environ, "TZ": "Europe/Madrid"}
    failed = 0
    total = 0

    print("== 1. Running check_air_quality.py ==")
    res = subprocess.run([sys.executable, str(REPO_ROOT / "tests/check_air_quality.py")], env=env, cwd=REPO_ROOT)
    total += 1
    if res.returncode != 0:
        failed += 1
        print("FAIL: check_air_quality.py\n")

    print("\n== 2. Running check_i18n.py ==")
    res = subprocess.run([sys.executable, str(REPO_ROOT / "tests/check_i18n.py")], env=env, cwd=REPO_ROOT)
    total += 1
    if res.returncode != 0:
        failed += 1
        print("FAIL: check_i18n.py\n")

    luau_bin = shutil.which("luau")
    if luau_bin:
        print("\n== 3. Running forecast_test.luau ==")
        res = subprocess.run([luau_bin, str(REPO_ROOT / "tests/forecast_test.luau")], env=env, cwd=REPO_ROOT)
        total += 1
        if res.returncode != 0:
            failed += 1
            print("FAIL: forecast_test.luau\n")
    else:
        print("\n[SKIP] forecast_test.luau: luau binary not found")

    print("\n==========================================")
    print(f"Results: {total - failed}/{total} test suites passed.")
    if failed:
        sys.exit(1)
    print("All meteogalicia tests passed successfully!")


if __name__ == "__main__":
    main()
