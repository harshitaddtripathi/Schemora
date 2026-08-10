"""Validate the complete Schemora Phase 0 data architecture."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Any, Iterable

from jsonschema import Draft202012Validator, FormatChecker
from PIL import Image
from referencing import Registry, Resource


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
SCHEMAS = DATA / "schemas"
VALIDATOR_VERSION = "v1"
WATERMARK = "SAMPLE - NOT VALID"


@dataclass
class Issue:
    location: str
    message: str


class Phase0Validator:
    def __init__(self, *, skip_manifest: bool = False) -> None:
        self.skip_manifest = skip_manifest
        self.issues: list[Issue] = []
        self.schemas: dict[str, dict[str, Any]] = {}
        self.registry = Registry()

    def add_issue(self, location: str, message: str) -> None:
        self.issues.append(Issue(location, message))

    def load_json(self, path: Path) -> Any:
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            self.add_issue(path.as_posix(), f"Cannot load JSON: {exc}")
            return None

    def load_schemas(self) -> None:
        for path in sorted(SCHEMAS.glob("*.json")):
            schema = self.load_json(path)
            if not isinstance(schema, dict):
                continue
            try:
                Draft202012Validator.check_schema(schema)
            except Exception as exc:  # jsonschema exposes several schema exceptions
                self.add_issue(path.as_posix(), f"Invalid Draft 2020-12 schema: {exc}")
                continue
            schema_id = schema.get("$id")
            if not isinstance(schema_id, str):
                self.add_issue(path.as_posix(), "Schema has no string $id")
                continue
            self.schemas[path.name] = schema
            self.registry = self.registry.with_resource(
                schema_id,
                Resource.from_contents(schema),
            )

    def validate_schema_instance(
        self,
        instance: Any,
        schema_name: str,
        location: str,
    ) -> None:
        schema = self.schemas.get(schema_name)
        if schema is None:
            self.add_issue(location, f"Schema not loaded: {schema_name}")
            return
        validator = Draft202012Validator(
            schema,
            registry=self.registry,
            format_checker=FormatChecker(),
        )
        for error in sorted(validator.iter_errors(instance), key=lambda item: list(item.path)):
            suffix = "/".join(str(part) for part in error.absolute_path)
            error_location = f"{location}:{suffix}" if suffix else location
            self.add_issue(error_location, error.message)

    @staticmethod
    def read_csv(path: Path) -> list[dict[str, str]]:
        with path.open("r", encoding="utf-8-sig", newline="") as handle:
            return list(csv.DictReader(handle))

    @staticmethod
    def normalize_source_row(row: dict[str, str]) -> dict[str, Any]:
        normalized: dict[str, Any] = dict(row)
        for field in ("publication_date", "effective_from", "effective_to", "application_cycle"):
            if normalized.get(field) == "":
                normalized[field] = None
        return normalized

    @staticmethod
    def normalize_inventory_row(row: dict[str, str]) -> dict[str, Any]:
        normalized: dict[str, Any] = dict(row)
        if normalized.get("state") == "":
            normalized["state"] = None
        return normalized

    @staticmethod
    def flatten_rule_nodes(node: dict[str, Any]) -> Iterable[dict[str, Any]]:
        yield node
        if node.get("type") in {"and", "or"}:
            for child in node.get("conditions", []):
                yield from Phase0Validator.flatten_rule_nodes(child)

    @staticmethod
    def flatten_leaf_rules(node: dict[str, Any]) -> list[dict[str, Any]]:
        return [
            item
            for item in Phase0Validator.flatten_rule_nodes(node)
            if item.get("type") == "condition"
        ]

    @staticmethod
    def is_missing(value: Any) -> bool:
        return value is None or value == "unknown"

    @staticmethod
    def evaluate_operator(actual: Any, operator: str, expected: Any) -> bool:
        if operator == "eq":
            return actual == expected
        if operator == "neq":
            return actual != expected
        if operator == "gt":
            return actual > expected
        if operator == "gte":
            return actual >= expected
        if operator == "lt":
            return actual < expected
        if operator == "lte":
            return actual <= expected
        if operator == "in":
            return actual in expected
        if operator == "not_in":
            return actual not in expected
        if operator == "contains":
            return expected in actual
        if operator == "exists":
            return not Phase0Validator.is_missing(actual)
        raise ValueError(f"Unsupported operator: {operator}")

    def evaluate_rule(
        self,
        node: dict[str, Any],
        profile: dict[str, Any],
        outcomes: dict[str, str],
    ) -> str:
        rule_type = node["type"]
        if rule_type == "condition":
            rule_id = node["rule_id"]
            if node["verification_status"] != "Verified":
                outcomes[rule_id] = "unresolved"
                return "unresolved"
            actual = profile.get(node["field"])
            if self.is_missing(actual):
                outcomes[rule_id] = "unresolved"
                return "unresolved"
            try:
                passed = self.evaluate_operator(actual, node["operator"], node["value"])
            except (TypeError, ValueError) as exc:
                self.add_issue(
                    f"rule:{rule_id}",
                    f"Cannot evaluate operator against profile value: {exc}",
                )
                outcomes[rule_id] = "unresolved"
                return "unresolved"
            outcome = "passed" if passed else "failed"
            outcomes[rule_id] = outcome
            return outcome

        child_results = [
            self.evaluate_rule(child, profile, outcomes)
            for child in node["conditions"]
        ]
        if rule_type == "and":
            if "failed" in child_results:
                return "failed"
            if "unresolved" in child_results:
                return "unresolved"
            return "passed"
        if rule_type == "or":
            if "passed" in child_results:
                return "passed"
            if "unresolved" in child_results:
                return "unresolved"
            return "failed"
        raise ValueError(f"Unsupported group type: {rule_type}")

    @staticmethod
    def status_from_outcome(outcome: str) -> str:
        return {
            "passed": "RuleMatched",
            "unresolved": "NeedsInformation",
            "failed": "NotMatched",
        }[outcome]

    @staticmethod
    def calculate_age(date_of_birth: str, as_of: str) -> int:
        born = date.fromisoformat(date_of_birth)
        reference = date.fromisoformat(as_of)
        return reference.year - born.year - (
            (reference.month, reference.day) < (born.month, born.day)
        )

    @staticmethod
    def sha256_file(path: Path) -> str:
        digest = hashlib.sha256()
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(65536), b""):
                digest.update(chunk)
        return digest.hexdigest()

    def validate_main_documents(self) -> dict[str, Any]:
        paths = {
            "schemes": DATA / "schemes" / "schemes.v1.json",
            "profiles": DATA / "benchmark_profiles" / "profiles.v1.json",
            "results": DATA / "benchmark_profiles" / "expected-results.v1.json",
            "confidence": DATA / "config" / "confidence-weights.json",
            "ranking": DATA / "config" / "ranking-weights.json",
        }
        documents = {name: self.load_json(path) for name, path in paths.items()}
        schema_map = {
            "schemes": "scheme.schema.json",
            "profiles": "benchmark-profile.schema.json",
            "results": "expected-result.schema.json",
            "confidence": "confidence-weights.schema.json",
            "ranking": "ranking-weights.schema.json",
        }
        for name, document in documents.items():
            if document is not None:
                self.validate_schema_instance(
                    document,
                    schema_map[name],
                    paths[name].as_posix(),
                )
        return documents

    def validate_csv_documents(
        self,
    ) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
        source_path = DATA / "sources" / "source-register.csv"
        inventory_path = DATA / "schemes" / "scheme-inventory.v1.csv"
        try:
            sources = [
                self.normalize_source_row(row)
                for row in self.read_csv(source_path)
            ]
        except OSError as exc:
            self.add_issue(source_path.as_posix(), str(exc))
            sources = []
        try:
            inventory = [
                self.normalize_inventory_row(row)
                for row in self.read_csv(inventory_path)
            ]
        except OSError as exc:
            self.add_issue(inventory_path.as_posix(), str(exc))
            inventory = []

        for index, source in enumerate(sources, start=2):
            self.validate_schema_instance(
                source,
                "source-record.schema.json",
                f"{source_path.as_posix()}:row-{index}",
            )
        for index, item in enumerate(inventory, start=2):
            self.validate_schema_instance(
                item,
                "scheme-inventory.schema.json",
                f"{inventory_path.as_posix()}:row-{index}",
            )
        return sources, inventory

    def validate_cross_references(
        self,
        documents: dict[str, Any],
        sources: list[dict[str, Any]],
        inventory: list[dict[str, Any]],
    ) -> None:
        if not all(documents.get(name) for name in ("schemes", "profiles", "results")):
            return

        schemes = documents["schemes"]["schemes"]
        profiles = documents["profiles"]["profiles"]
        results = documents["results"]["results"]

        scheme_by_id = {scheme["scheme_id"]: scheme for scheme in schemes}
        profile_by_id = {profile["profile_id"]: profile for profile in profiles}
        source_by_id = {source["source_id"]: source for source in sources}
        inventory_by_id = {item["scheme_id"]: item for item in inventory}

        self.assert_unique(
            [scheme["scheme_id"] for scheme in schemes],
            "data/schemes/schemes.v1.json",
            "scheme_id",
        )
        self.assert_unique(
            [profile["profile_id"] for profile in profiles],
            "data/benchmark_profiles/profiles.v1.json",
            "profile_id",
        )
        self.assert_unique(
            [source["source_id"] for source in sources],
            "data/sources/source-register.csv",
            "source_id",
        )
        self.assert_unique(
            [item["scheme_id"] for item in inventory],
            "data/schemes/scheme-inventory.v1.csv",
            "scheme_id",
        )

        if len(inventory) != 25:
            self.add_issue("scheme-inventory.v1.csv", f"Expected 25 rows, found {len(inventory)}")
        implemented = {
            item["scheme_id"]
            for item in inventory
            if item["implementation_status"] == "Implemented"
        }
        if len(implemented) != 3:
            self.add_issue("scheme-inventory.v1.csv", f"Expected 3 implemented rows, found {len(implemented)}")
        if implemented != set(scheme_by_id):
            self.add_issue(
                "scheme-inventory.v1.csv",
                "Implemented inventory IDs must exactly match schemes.v1.json IDs",
            )

        for item in inventory:
            if item["jurisdiction"] == "Central" and item["state"] is not None:
                self.add_issue(item["scheme_id"], "Central inventory rows must have state=null")
            if item["jurisdiction"] == "State" and item["state"] is None:
                self.add_issue(item["scheme_id"], "State inventory rows must specify a state")
            if item["implementation_status"] == "PlannedResearch":
                if item["scheme_name"] != "verification_required":
                    self.add_issue(item["scheme_id"], "Planned rows must not invent a scheme name")

        for source in sources:
            if source["scheme_id"] not in scheme_by_id:
                self.add_issue(source["source_id"], "Source references an unimplemented scheme")

        for scheme in schemes:
            scheme_id = scheme["scheme_id"]
            if scheme["jurisdiction"] == "Central" and scheme["state"] is not None:
                self.add_issue(scheme_id, "Central schemes must have state=null")
            if scheme["jurisdiction"] == "State" and scheme["state"] is None:
                self.add_issue(scheme_id, "State schemes must specify a state")

            scheme_sources = set(scheme["source_documents"])
            for source_id in scheme_sources:
                source = source_by_id.get(source_id)
                if source is None:
                    self.add_issue(scheme_id, f"Unknown source_documents ID: {source_id}")
                elif source["scheme_id"] != scheme_id:
                    self.add_issue(scheme_id, f"Source {source_id} belongs to another scheme")

            referenced_sources: set[str] = set()
            for rule in self.flatten_rule_nodes(scheme["eligibility_rules"]["root"]):
                referenced_sources.update(rule.get("source_ids", []))
            for collection in (
                scheme["benefits"],
                scheme["required_documents"],
                scheme["application_process"],
                scheme["application_windows"],
            ):
                for item in collection:
                    referenced_sources.update(item["source_ids"])
            for source_id in referenced_sources:
                if source_id not in scheme_sources:
                    self.add_issue(
                        scheme_id,
                        f"Referenced source {source_id} is missing from source_documents",
                    )

            self.assert_unique(
                [node["rule_id"] for node in self.flatten_rule_nodes(scheme["eligibility_rules"]["root"])],
                scheme_id,
                "rule_id",
            )
            self.assert_unique(
                [item["document_id"] for item in scheme["required_documents"]],
                scheme_id,
                "document_id",
            )

        for profile in profiles:
            calculated = self.calculate_age(profile["date_of_birth"], profile["age_as_of"])
            if profile["age"] != calculated:
                self.add_issue(
                    profile["profile_id"],
                    f"Age {profile['age']} does not match date_of_birth at age_as_of ({calculated})",
                )

        seen_pairs: set[tuple[str, str]] = set()
        for result in results:
            pair = (result["profile_id"], result["scheme_id"])
            if pair in seen_pairs:
                self.add_issue(str(pair), "Duplicate profile/scheme expected result")
            seen_pairs.add(pair)

            profile = profile_by_id.get(result["profile_id"])
            scheme = scheme_by_id.get(result["scheme_id"])
            if profile is None:
                self.add_issue(str(pair), "Unknown profile_id")
                continue
            if scheme is None:
                self.add_issue(str(pair), "Expected results may reference implemented schemes only")
                continue

            rule_ids = {
                rule["rule_id"]
                for rule in self.flatten_leaf_rules(scheme["eligibility_rules"]["root"])
            }
            result_rule_sets = [
                set(result["passed_rule_ids"]),
                set(result["failed_rule_ids"]),
                set(result["unresolved_rule_ids"]),
            ]
            if any(result_rule_sets[index] & result_rule_sets[other] for index in range(3) for other in range(index + 1, 3)):
                self.add_issue(str(pair), "Passed, failed, and unresolved rule IDs must be disjoint")
            if set().union(*result_rule_sets) != rule_ids:
                self.add_issue(str(pair), "Expected rule IDs must cover every leaf rule exactly once")

            outcomes: dict[str, str] = {}
            root_outcome = self.evaluate_rule(
                scheme["eligibility_rules"]["root"],
                profile,
                outcomes,
            )
            actual_status = self.status_from_outcome(root_outcome)
            if actual_status != result["expected_status"]:
                self.add_issue(
                    str(pair),
                    f"Expected status {result['expected_status']} does not match evaluated {actual_status}",
                )
            for label, expected_ids in (
                ("passed", result["passed_rule_ids"]),
                ("failed", result["failed_rule_ids"]),
                ("unresolved", result["unresolved_rule_ids"]),
            ):
                evaluated_ids = {rule_id for rule_id, outcome in outcomes.items() if outcome == label}
                if set(expected_ids) != evaluated_ids:
                    self.add_issue(
                        str(pair),
                        f"{label} rule IDs do not match deterministic evaluation",
                    )

            document_ids = {
                item["document_id"]
                for item in scheme["required_documents"]
            }
            if not set(result["expected_document_ids"]).issubset(document_ids):
                self.add_issue(str(pair), "Expected result references unknown document IDs")
            if not set(result["supporting_source_ids"]).issubset(set(scheme["source_documents"])):
                self.add_issue(str(pair), "Expected result references unsupported source IDs")

        expected_pairs = {
            (profile_id, scheme_id)
            for profile_id in profile_by_id
            for scheme_id in scheme_by_id
        }
        if seen_pairs != expected_pairs:
            self.add_issue(
                "expected-results.v1.json",
                "Expected results must contain one row for every profile and implemented scheme",
            )

    def assert_unique(self, values: list[str], location: str, field: str) -> None:
        duplicates = sorted({value for value in values if values.count(value) > 1})
        if duplicates:
            self.add_issue(location, f"Duplicate {field} values: {', '.join(duplicates)}")

    def validate_weights(self, documents: dict[str, Any]) -> None:
        for name in ("confidence", "ranking"):
            document = documents.get(name)
            if not document:
                continue
            calculated = sum(document["components"].values())
            if calculated != document["total"] or calculated != 100:
                self.add_issue(
                    f"data/config/{name}-weights.json",
                    f"Component total must equal 100, found {calculated}",
                )

    def validate_synthetic_documents(self) -> None:
        expected_variants = {
            "aadhaar": {"valid", "blurred", "incomplete", "profile_mismatch"},
            "pan": {"valid", "blurred", "incomplete", "profile_mismatch"},
            "income_certificate": {"valid", "blurred", "incomplete", "profile_mismatch", "expired"},
        }
        for folder_name, variants in expected_variants.items():
            folder = DATA / "synthetic_documents" / folder_name
            pngs = {path.stem.split(f"{folder_name}_", 1)[-1]: path for path in folder.glob("*.png")}
            if set(pngs) != variants:
                self.add_issue(
                    folder.as_posix(),
                    f"Expected variants {sorted(variants)}, found {sorted(pngs)}",
                )
            for variant, image_path in pngs.items():
                sidecar_path = image_path.with_suffix(".json")
                sidecar = self.load_json(sidecar_path)
                if sidecar is None:
                    continue
                self.validate_schema_instance(
                    sidecar,
                    "synthetic-document.schema.json",
                    sidecar_path.as_posix(),
                )
                if sidecar.get("image_sha256") != self.sha256_file(image_path):
                    self.add_issue(sidecar_path.as_posix(), "Image SHA-256 does not match")
                try:
                    with Image.open(image_path) as image:
                        if image.info.get("watermark") != WATERMARK:
                            self.add_issue(image_path.as_posix(), "PNG watermark metadata is missing")
                        if image.width < 1000 or image.height < 600:
                            self.add_issue(image_path.as_posix(), "Fixture resolution is too small")
                except OSError as exc:
                    self.add_issue(image_path.as_posix(), f"Cannot open image: {exc}")
                if sidecar.get("variant") != variant:
                    self.add_issue(sidecar_path.as_posix(), "Sidecar variant does not match filename")

    def validate_sensitive_content(self) -> None:
        aadhaar_pattern = re.compile(
            r"(?<![A-Za-z0-9])\d{4}[ -]?\d{4}[ -]?\d{4}(?![A-Za-z0-9])"
        )
        pan_pattern = re.compile(r"\b[A-Z]{5}[0-9]{4}[A-Z]\b")
        secret_patterns = [
            re.compile(r"-----BEGIN (?:RSA |EC )?PRIVATE KEY-----"),
            re.compile(r"\bAIza[0-9A-Za-z_-]{30,}\b"),
            re.compile(r"\beyJ[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]{20,}\b"),
        ]
        allowed_suffixes = {".json", ".csv", ".md", ".py", ".txt", ".example", ".gitignore"}
        for path in ROOT.rglob("*"):
            if not path.is_file():
                continue
            if ".git" in path.parts or ".venv" in path.parts:
                continue
            if path.suffix not in allowed_suffixes and path.name != ".gitignore":
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            if aadhaar_pattern.search(text):
                self.add_issue(path.as_posix(), "Possible complete Aadhaar number found")
            if pan_pattern.search(text):
                self.add_issue(path.as_posix(), "Possible complete PAN number found")
            if path.name != ".env.example":
                for pattern in secret_patterns:
                    if pattern.search(text):
                        self.add_issue(path.as_posix(), "Possible real secret found")

    def validate_manifest(self) -> None:
        manifest_path = DATA / "dataset-manifest.v1.json"
        if self.skip_manifest:
            return
        manifest = self.load_json(manifest_path)
        if manifest is None:
            self.add_issue(manifest_path.as_posix(), "Manifest is required for final validation")
            return
        self.validate_schema_instance(
            manifest,
            "dataset-manifest.schema.json",
            manifest_path.as_posix(),
        )
        for item in manifest.get("files", []):
            path = ROOT / item["path"]
            if not path.is_file():
                self.add_issue(manifest_path.as_posix(), f"Manifest file is missing: {item['path']}")
                continue
            actual_hash = self.sha256_file(path)
            if actual_hash != item["sha256"]:
                self.add_issue(manifest_path.as_posix(), f"Manifest hash mismatch: {item['path']}")

    def run(self) -> int:
        self.load_schemas()
        documents = self.validate_main_documents()
        sources, inventory = self.validate_csv_documents()
        self.validate_cross_references(documents, sources, inventory)
        self.validate_weights(documents)
        self.validate_synthetic_documents()
        self.validate_sensitive_content()
        self.validate_manifest()

        if self.issues:
            print(f"Phase 0 validation FAILED with {len(self.issues)} issue(s):")
            for issue in self.issues:
                print(f"- {issue.location}: {issue.message}")
            return 1

        print("Phase 0 validation PASSED.")
        print(f"Validator version: {VALIDATOR_VERSION}")
        validated_scope = "schemas, datasets, cross-references, benchmarks, fixtures, weights, secrets, and identifiers"
        if not self.skip_manifest:
            validated_scope += ", and the frozen manifest"
        print(f"Validated {validated_scope}.")
        return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--skip-manifest",
        action="store_true",
        help="Run the initial validation before the frozen manifest is generated.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    arguments = parse_args()
    sys.exit(Phase0Validator(skip_manifest=arguments.skip_manifest).run())
