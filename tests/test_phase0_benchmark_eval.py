import json
from pathlib import Path
import pytest
from scripts.validate_phase0 import Phase0Validator

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

validator = Phase0Validator(skip_manifest=True)


@pytest.fixture(scope="module")
def benchmark_data():
    schemes = json.loads((DATA / "schemes" / "schemes.v1.json").read_text(encoding="utf-8"))["schemes"]
    profiles = json.loads((DATA / "benchmark_profiles" / "profiles.v1.json").read_text(encoding="utf-8"))["profiles"]
    results = json.loads((DATA / "benchmark_profiles" / "expected-results.v1.json").read_text(encoding="utf-8"))["results"]

    scheme_map = {s["scheme_id"]: s for s in schemes}
    profile_map = {p["profile_id"]: p for p in profiles}
    return scheme_map, profile_map, results


def test_45_benchmark_profile_scheme_evaluations(benchmark_data):
    scheme_map, profile_map, results = benchmark_data
    assert len(results) == 45, f"Expected 45 expected results (15 profiles x 3 schemes), got {len(results)}"

    failures = []
    for res in results:
        profile_id = res["profile_id"]
        scheme_id = res["scheme_id"]
        profile = profile_map[profile_id]
        scheme = scheme_map[scheme_id]

        outcomes = {}
        root_outcome = validator.evaluate_rule(scheme["eligibility_rules"]["root"], profile, outcomes)
        actual_status = validator.status_from_outcome(root_outcome)

        if actual_status != res["expected_status"]:
            failures.append(
                f"[{profile_id} - {scheme_id}] Expected {res['expected_status']}, got {actual_status}"
            )

        passed_ids = {r_id for r_id, out in outcomes.items() if out == "passed"}
        failed_ids = {r_id for r_id, out in outcomes.items() if out == "failed"}
        unresolved_ids = {r_id for r_id, out in outcomes.items() if out == "unresolved"}

        if set(res["passed_rule_ids"]) != passed_ids:
            failures.append(f"[{profile_id} - {scheme_id}] Passed rule IDs mismatch: expected {res['passed_rule_ids']}, got {sorted(passed_ids)}")
        if set(res["failed_rule_ids"]) != failed_ids:
            failures.append(f"[{profile_id} - {scheme_id}] Failed rule IDs mismatch: expected {res['failed_rule_ids']}, got {sorted(failed_ids)}")
        if set(res["unresolved_rule_ids"]) != unresolved_ids:
            failures.append(f"[{profile_id} - {scheme_id}] Unresolved rule IDs mismatch: expected {res['unresolved_rule_ids']}, got {sorted(unresolved_ids)}")

    assert not failures, "Benchmark evaluation mismatches:\n" + "\n".join(failures)
