import json
from pathlib import Path
import pytest
from jsonschema import Draft202012Validator, FormatChecker
from referencing import Registry, Resource

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
SCHEMAS = DATA / "schemas"


@pytest.fixture(scope="module")
def schema_registry():
    registry = Registry()
    schemas = {}
    for path in sorted(SCHEMAS.glob("*.json")):
        schema = json.loads(path.read_text(encoding="utf-8"))
        Draft202012Validator.check_schema(schema)
        schema_id = schema.get("$id")
        if schema_id:
            registry = registry.with_resource(schema_id, Resource.from_contents(schema))
        schemas[path.name] = schema
    return schemas, registry


def validate_instance(schema_name, instance, schemas, registry):
    schema = schemas[schema_name]
    validator = Draft202012Validator(schema, registry=registry, format_checker=FormatChecker())
    errors = list(validator.iter_errors(instance))
    assert not errors, f"Schema validation errors for {schema_name}: {[e.message for e in errors]}"


def test_scheme_schema_validation(schema_registry):
    schemas, registry = schema_registry
    schemes_data = json.loads((DATA / "schemes" / "schemes.v1.json").read_text(encoding="utf-8"))
    validate_instance("scheme.schema.json", schemes_data, schemas, registry)


def test_benchmark_profile_schema_validation(schema_registry):
    schemas, registry = schema_registry
    profiles_data = json.loads((DATA / "benchmark_profiles" / "profiles.v1.json").read_text(encoding="utf-8"))
    validate_instance("benchmark-profile.schema.json", profiles_data, schemas, registry)


def test_expected_result_schema_validation(schema_registry):
    schemas, registry = schema_registry
    results_data = json.loads((DATA / "benchmark_profiles" / "expected-results.v1.json").read_text(encoding="utf-8"))
    validate_instance("expected-result.schema.json", results_data, schemas, registry)


def test_confidence_weights_schema_validation(schema_registry):
    schemas, registry = schema_registry
    confidence_data = json.loads((DATA / "config" / "confidence-weights.json").read_text(encoding="utf-8"))
    validate_instance("confidence-weights.schema.json", confidence_data, schemas, registry)


def test_ranking_weights_schema_validation(schema_registry):
    schemas, registry = schema_registry
    ranking_data = json.loads((DATA / "config" / "ranking-weights.json").read_text(encoding="utf-8"))
    validate_instance("ranking-weights.schema.json", ranking_data, schemas, registry)


def test_manifest_schema_validation(schema_registry):
    schemas, registry = schema_registry
    manifest_data = json.loads((DATA / "dataset-manifest.v1.json").read_text(encoding="utf-8"))
    validate_instance("dataset-manifest.schema.json", manifest_data, schemas, registry)


def test_synthetic_documents_schema_validation(schema_registry):
    schemas, registry = schema_registry
    for sidecar_path in (DATA / "synthetic_documents").rglob("*.json"):
        if sidecar_path.name.endswith(".schema.json"):
            continue
        sidecar_data = json.loads(sidecar_path.read_text(encoding="utf-8"))
        validate_instance("synthetic-document.schema.json", sidecar_data, schemas, registry)
