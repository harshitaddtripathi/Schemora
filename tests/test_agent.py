"""Schemora QA Testing Agent.

Executes comprehensive E2E test suites for Phase 0, Phase 1, Phase 2, Phase 3, Phase 4, Phase 5, and Phase 6,
analyzes execution failures, verifies fixes, and logs results.
"""

import argparse
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class QATestingAgent:
    def __init__(self) -> None:
        self.results: dict[str, dict] = {}
        self.start_time = time.time()

    def run_cmd(self, name: str, cmd: list[str], cwd: Path) -> dict:
        print(f"\n==================================================")
        print(f"  [QA Agent] Executing: {name}")
        print(f"  Command: {' '.join(cmd)}")
        print(f"  Directory: {cwd}")
        print(f"==================================================")

        t0 = time.time()
        use_shell = os.name == "nt"
        res = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, shell=use_shell)
        duration = round(time.time() - t0, 2)

        status = "PASS" if res.returncode == 0 else "FAIL"

        print(f"  Status: {status} (Exit code: {res.returncode}, Duration: {duration}s)")
        if res.stdout:
            print(f"\n--- Output ---\n{res.stdout.strip()}")
        if res.stderr and res.returncode != 0:
            print(f"\n--- Errors ---\n{res.stderr.strip()}")

        result_item = {
            "name": name,
            "status": status,
            "exit_code": res.returncode,
            "duration_s": duration,
            "stdout": res.stdout,
            "stderr": res.stderr,
        }
        self.results[name] = result_item
        return result_item

    def run_all(self) -> bool:
        # 1. Root Pytest Suite (Phases 0-8)
        self.run_cmd(
            "Full Integration Pytest Suite (Phases 0-8)",
            ["uv", "run", "--with-requirements", "requirements-phase0.txt", "pytest", "tests/"],
            ROOT,
        )

        # 2. Phase 0 Validator Script
        self.run_cmd(
            "Phase 0 Manifest & Data Validator",
            ["uv", "run", "--with-requirements", "requirements-phase0.txt", "python", "scripts/validate_phase0.py"],
            ROOT,
        )

        # 3. Backend Pytest Suite
        self.run_cmd(
            "Backend Service Pytest Suite",
            ["uv", "run", "pytest"],
            ROOT / "backend",
        )

        # 4. Frontend Flutter Static Analysis
        self.run_cmd(
            "Frontend Flutter Static Analysis",
            ["flutter", "analyze"],
            ROOT / "frontend",
        )

        # 5. Frontend Flutter Widget & Unit Tests
        self.run_cmd(
            "Frontend Flutter Widget & Unit Tests",
            ["flutter", "test"],
            ROOT / "frontend",
        )

        all_passed = all(item["status"] == "PASS" for item in self.results.values())
        total_duration = round(time.time() - self.start_time, 2)

        print("\n==================================================")
        print("           QA AGENT EXECUTION SUMMARY             ")
        print("==================================================")
        for name, item in self.results.items():
            print(f"  [{item['status']}] {name} ({item['duration_s']}s)")
        print(f"\nOverall Result: {'PASSED' if all_passed else 'FAILED'} (Total: {total_duration}s)")
        print("==================================================")

        return all_passed


def main() -> None:
    agent = QATestingAgent()
    success = agent.run_all()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
