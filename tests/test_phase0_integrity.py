import csv
import json
from datetime import date
from pathlib import Path
import pytest

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def read_csv(path: Path):
    with path.open("r", encoding="utf-8-sig", newline="") as h:
        return list(csv.DictReader(h))


@pytest.fixture(scope="module")
def dataset():
    schemes = json.loads((DATA / "schemes" / "schemes.v1.json").read_text(encoding="utf-8"))["schemes"]
    profiles = json.loads((DATA / "benchmark_profiles" / "profiles.v1.json").read_text(encoding="utf-8"))["profiles"]
    results = json.loads((DATA / "benchmark_profiles" / "expected-results.v1.json").read_text(encoding="utf-8"))["results"]
    inventory = read_csv(DATA / "schemes" / "scheme-inventory.v1.csv")
    sources = read_csv(DATA / "sources" / "source-register.csv")
    return {
        "schemes": schemes,
        "profiles": profiles,
        "results": results,
        "inventory": inventory,
        "sources": sources,
    }


def test_unique_identifiers(dataset):
    scheme_ids = [s["scheme_id"] for s in dataset["schemes"]]
    assert len(scheme_ids) == len(set(scheme_ids)), "Duplicate scheme_id found"

    profile_ids = [p["profile_id"] for p in dataset["profiles"]]
    assert len(profile_ids) == len(set(profile_ids)), "Duplicate profile_id found"

    source_ids = [s["source_id"] for s in dataset["sources"]]
    assert len(source_ids) == len(set(source_ids)), "Duplicate source_id found"

    inv_ids = [i["scheme_id"] for i in dataset["inventory"]]
    assert len(inv_ids) == len(set(inv_ids)), "Duplicate inventory scheme_id found"


def test_inventory_counts(dataset):
    inventory = dataset["inventory"]
    assert len(inventory) == 25, f"Expected 25 inventory slots, got {len(inventory)}"

    implemented = [i for i in inventory if i["implementation_status"] == "Implemented"]
    assert len(implemented) == 3, f"Expected 3 implemented schemes, got {len(implemented)}"

    planned = [i for i in inventory if i["implementation_status"] == "PlannedResearch"]
    assert len(planned) == 22, f"Expected 22 planned schemes, got {len(planned)}"

    for p in planned:
        assert p["scheme_name"] == "verification_required", "Planned research slot must have scheme_name 'verification_required'"


def test_jurisdiction_state_consistency(dataset):
    for scheme in dataset["schemes"]:
        if scheme["jurisdiction"] == "Central":
            assert scheme["state"] is None, f"Central scheme {scheme['scheme_id']} must have state=null"
        elif scheme["jurisdiction"] == "State":
            assert scheme["state"] is not None, f"State scheme {scheme['scheme_id']} must specify a state"

    for inv in dataset["inventory"]:
        if inv["jurisdiction"] == "Central":
            assert inv["state"] == "" or inv["state"] is None, f"Central inventory row {inv['scheme_id']} must have empty state"
        elif inv["jurisdiction"] == "State":
            assert inv["state"] != "", f"State inventory row {inv['scheme_id']} must specify state"


def test_profile_age_calculation(dataset):
    for profile in dataset["profiles"]:
        born = date.fromisoformat(profile["date_of_birth"])
        ref = date.fromisoformat(profile["age_as_of"])
        expected_age = ref.year - born.year - ((ref.month, ref.day) < (born.month, born.day))
        assert profile["age"] == expected_age, (
            f"Profile {profile['profile_id']} recorded age {profile['age']} "
            f"does not match calculated age {expected_age}"
        )


def test_source_cross_references(dataset):
    source_map = {s["source_id"]: s for s in dataset["sources"]}
    scheme_map = {s["scheme_id"]: s for s in dataset["schemes"]}

    for source in dataset["sources"]:
        assert source["scheme_id"] in scheme_map, f"Source {source['source_id']} references unknown scheme {source['scheme_id']}"

    for scheme in dataset["schemes"]:
        declared_sources = set(scheme["source_documents"])
        for src_id in declared_sources:
            assert src_id in source_map, f"Scheme {scheme['scheme_id']} references non-existent source_id {src_id}"
            assert source_map[src_id]["scheme_id"] == scheme["scheme_id"], (
                f"Source {src_id} assigned to scheme {source_map[src_id]['scheme_id']} instead of {scheme['scheme_id']}"
            )
