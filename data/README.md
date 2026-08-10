# Schemora Phase 0 Data

This directory contains the versioned data architecture for the Schemora academic MVP.

No Flutter, backend API, authentication, OCR runtime, AI agent, or RAG implementation belongs here.

## Structure

```text
data/
  schemas/                 JSON Schema Draft 2020-12 contracts
  schemes/                 Implemented pilot records and 25-slot inventory
  sources/                 Official-source register
  benchmark_profiles/      Synthetic profiles and expected eligibility results
  config/                  Confidence and future ranking weights
  synthetic_documents/     Watermarked OCR image fixtures and JSON sidecars
  dataset-manifest.v1.json Frozen file hashes and dataset counts
```

## Versioning

- `schemes.v1.json` contains only fully structured pilot records.
- `scheme-inventory.v1.csv` contains three implemented records and 22 planned research slots.
- `profiles.v1.json` and `expected-results.v1.json` form one benchmark version.
- Scheme records carry independent `scheme_version` values because government sources change asynchronously.
- `verification_required` and `VerificationRequired` are deliberate values, not missing-data mistakes.

## Validation

Install Phase 0 dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-phase0.txt
```

Regenerate synthetic fixtures:

```powershell
.\.venv\Scripts\python.exe scripts\generate_synthetic_documents.py
```

Run initial validation:

```powershell
.\.venv\Scripts\python.exe scripts\validate_phase0.py --skip-manifest
```

Build the frozen manifest and run final validation:

```powershell
.\.venv\Scripts\python.exe scripts\build_phase0_manifest.py
.\.venv\Scripts\python.exe scripts\validate_phase0.py
```

The final validator must pass before any application-development phase begins.
