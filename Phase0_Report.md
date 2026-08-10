# Schemora Phase 0 Report

Report date: August 7, 2026

## Scope

Phase 0 created and validated the project data architecture only.

It did not create:

- Flutter code
- FastAPI or backend APIs
- Database models
- Authentication
- OCR runtime integration
- AI agents
- RAG ingestion or retrieval

## Completed Outputs

- JSON Schema Draft 2020-12 contracts
- Three implemented pilot scheme records
- A 25-slot inventory with 22 unimplemented research slots
- Seven official-source records
- Fifteen synthetic student profiles
- Forty-five per-profile, per-scheme expected eligibility results
- Confidence and future ranking configurations
- Thirteen synthetic OCR images and thirteen sidecars
- Standalone validation and manifest tooling
- Infrastructure environment placeholders
- Phase 0.1 expansion plan

## Folder Structure

```text
data/
  schemas/
  schemes/
  sources/
  benchmark_profiles/
  config/
  synthetic_documents/
  dataset-manifest.v1.json
scripts/
  validate_phase0.py
  generate_synthetic_documents.py
  build_phase0_manifest.py
.env.example
requirements-phase0.txt
Phase0_Report.md
Phase0.1_Plan.md
```

## Schema Relationships

`common.schema.json` defines controlled enums and reusable primitives.

`eligibility-rule.schema.json` defines recursive AND, OR, and condition nodes. `scheme.schema.json` embeds this rule set in each scheme record.

`student-profile.schema.json` defines the reusable profile object. `benchmark-profile.schema.json` packages fifteen profiles as a versioned benchmark dataset.

`expected-result.schema.json` records expected rule and checklist outcomes. Cross-file validation confirms that every profile has exactly one result for every implemented scheme.

CSV records are validated by loading each row and applying `source-record.schema.json` or `scheme-inventory.schema.json`.

Synthetic sidecars use `synthetic-document.schema.json`. The dataset manifest uses `dataset-manifest.schema.json`.

## Pilot Scheme Verification

### CSSS

The Ministry of Education page is the primary scheme source and the National Scholarship Portal is treated only as the application portal.

The official 80th-percentile academic rule is represented as verified. Current benefit amounts, income threshold, course-mode wording, exclusion wording, required-document checklist, and application window remain `VerificationRequired` because a current detailed Ministry guideline snapshot was not available through the retrievable page content.

As a result, CSSS benchmark outcomes can be `NotMatched` on the verified percentile rule or `NeedsInformation`; they cannot become `RuleMatched` in this dataset version.

### Maharashtra Post Matric Scholarship to OBC Students

The exact VJNT, OBC and SBC Welfare Department scheme was used rather than a generic MahaDBT label.

The indexed official scheme content supports the modeled state, category, income, attendance, post-matric level, education-gap, CAP, family-limit, benefit, and document rules.

The dynamic official scheme and login pages returned 404 to automated retrieval on August 7, 2026. Their hashes, current application workflow, and application window remain `VerificationRequired` pending a manual browser snapshot.

### PM Internship Scheme

The dataset uses the latest official MY Bharat 2026 implementation and does not reuse older MCA-era portal or benefit assumptions.

Current age, qualification, full-time study, full-time employment, citizenship, monthly assistance, duration context, and MY Bharat application path are represented from official MY Bharat sources.

The complete current exclusion list, document checklist, and next application window remain `VerificationRequired`.

## Benchmark Design

The benchmark intentionally excludes Top 3 ranking tests because only three schemes are implemented.

It covers:

- Central and State schemes
- Multiple states and social categories
- Minority and disability values
- Undergraduate, postgraduate, diploma, ITI, and Class 12 profiles
- Nested OR behavior
- Numeric thresholds
- Missing values
- Verified failures
- Verification-required rules
- Checklist references

Expected status distribution:

- `RuleMatched`: 2
- `NeedsInformation`: 17
- `NotMatched`: 26

## Validation Process

`scripts/validate_phase0.py` validates:

- Draft 2020-12 schema correctness
- JSON and CSV schema compliance
- Unique IDs
- Cross-file foreign keys
- Source ownership
- Central-scheme `state: null`
- Exactly 25 inventory slots and three implemented records
- Rule and document references
- Deterministic three-state eligibility outcomes
- Complete benchmark profile/scheme coverage
- Confidence and ranking totals
- Synthetic fixture variants, hashes, dimensions, and watermark metadata
- No complete Aadhaar or PAN values
- No likely real secrets
- Frozen manifest file hashes

## Remaining Work

The following work is intentionally deferred:

- Obtain a current detailed CSSS Ministry guideline and update unresolved fields.
- Capture stable manual snapshots of the dynamic MahaDBT scheme and login pages.
- Verify the full current PM Internship exclusion and document requirements.
- Verify current application windows for all three pilots.
- Research and implement the remaining 22 inventory slots under Phase 0.1.
- Expand eligibility benchmarks as schemes are added.
- Begin application implementation only after Phase 0 approval.

## Phase 0 Gate

Phase 0 is complete only when:

1. The frozen manifest exists.
2. `scripts/validate_phase0.py` exits successfully without `--skip-manifest`.
3. The unresolved source fields are accepted as explicit limitations for the academic prototype.

Passing Phase 0 validates architecture and internal consistency. It does not certify government eligibility accuracy or production compliance.
