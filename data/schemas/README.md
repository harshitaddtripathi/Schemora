# Schema Relationships

All schemas use JSON Schema Draft 2020-12, stable `$id` identifiers, reusable `$defs`, and `additionalProperties: false`.

## Dependency Map

```text
common.schema.json
  <- eligibility-rule.schema.json
  <- student-profile.schema.json
  <- source-record.schema.json
  <- scheme-inventory.schema.json
  <- confidence-weights.schema.json
  <- ranking-weights.schema.json

eligibility-rule.schema.json
  <- scheme.schema.json

student-profile.schema.json
  <- benchmark-profile.schema.json

scheme.schema.json
  <- expected-result cross-file validation

synthetic-document.schema.json
  <- every synthetic image sidecar

dataset-manifest.schema.json
  <- data/dataset-manifest.v1.json
```

JSON Schema validates individual document structure. `scripts/validate_phase0.py` additionally validates CSV rows, IDs, foreign keys, source ownership, rule outcomes, benchmark coverage, file hashes, image metadata, weight totals, and privacy constraints.

## Eligibility Semantics

- `RuleMatched`: every mandatory group passes.
- `NeedsInformation`: no mandatory group fails and at least one condition is unresolved.
- `NotMatched`: at least one mandatory group fails.

A condition with `verification_status: VerificationRequired` is always unresolved. Confidence configuration never changes eligibility status.
