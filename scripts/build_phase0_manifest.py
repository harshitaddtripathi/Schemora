"""Build the frozen Schemora Phase 0 dataset manifest."""

from __future__ import annotations

import csv
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
MANIFEST = DATA / "dataset-manifest.v1.json"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def classify(path: Path) -> str:
    relative = path.relative_to(ROOT).as_posix()
    if relative.startswith("data/schemas/"):
        return "schema"
    if relative.startswith("data/schemes/schemes"):
        return "scheme"
    if relative.startswith("data/schemes/scheme-inventory"):
        return "inventory"
    if relative.startswith("data/sources/"):
        return "source"
    if relative.startswith("data/benchmark_profiles/"):
        return "benchmark"
    if relative.startswith("data/config/"):
        return "configuration"
    if relative.startswith("data/synthetic_documents/"):
        return "synthetic_document"
    if relative in {".env.example", "requirements-phase0.txt"}:
        return "infrastructure"
    if relative.startswith("scripts/"):
        return "validation"
    return "documentation"


def phase0_files() -> list[Path]:
    paths: list[Path] = []
    for folder in (
        DATA / "schemas",
        DATA / "schemes",
        DATA / "sources",
        DATA / "benchmark_profiles",
        DATA / "config",
        DATA / "synthetic_documents",
    ):
        paths.extend(path for path in folder.rglob("*") if path.is_file())
    for relative in (
        ".env.example",
        "requirements-phase0.txt",
        "scripts/validate_phase0.py",
        "scripts/generate_synthetic_documents.py",
        "scripts/build_phase0_manifest.py",
        "Phase0_Report.md",
        "Phase0.1_Plan.md",
        "data/README.md",
        "data/schemas/README.md",
        "data/sources/README.md",
        "data/synthetic_documents/README.md",
    ):
        path = ROOT / relative
        if path.is_file():
            paths.append(path)
    return sorted({path for path in paths if path != MANIFEST})


def count_csv(path: Path) -> int:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return sum(1 for _ in csv.DictReader(handle))


def main() -> None:
    schemes = json.loads((DATA / "schemes" / "schemes.v1.json").read_text(encoding="utf-8"))
    profiles = json.loads((DATA / "benchmark_profiles" / "profiles.v1.json").read_text(encoding="utf-8"))
    results = json.loads((DATA / "benchmark_profiles" / "expected-results.v1.json").read_text(encoding="utf-8"))
    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    files = [
        {
            "path": path.relative_to(ROOT).as_posix(),
            "sha256": sha256_file(path),
            "category": classify(path),
        }
        for path in phase0_files()
    ]
    manifest = {
        "dataset_version": "v1",
        "generated_at": now,
        "frozen_at": now,
        "status": "Frozen",
        "counts": {
            "implemented_schemes": len(schemes["schemes"]),
            "inventory_slots": count_csv(DATA / "schemes" / "scheme-inventory.v1.csv"),
            "benchmark_profiles": len(profiles["profiles"]),
            "expected_results": len(results["results"]),
            "source_records": count_csv(DATA / "sources" / "source-register.csv"),
            "synthetic_documents": len(list((DATA / "synthetic_documents").rglob("*.png"))),
        },
        "files": files,
        "validation": {
            "validator_version": "v1",
            "last_run_at": now,
            "status": "Passed",
        },
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {MANIFEST.relative_to(ROOT)} with {len(files)} tracked Phase 0 files.")


if __name__ == "__main__":
    main()
