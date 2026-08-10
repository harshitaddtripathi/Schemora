# Synthetic OCR Fixtures

These files are deterministic OCR test fixtures, not replicas of usable government documents.

Every image:

- Uses fictional identity data
- Contains the visible text `SAMPLE - NOT VALID`
- Contains PNG metadata confirming the watermark
- Has a JSON sidecar with expected OCR and verification behavior
- Stores only masked Aadhaar and PAN values

## Fixture Matrix

| Document | Variants |
| --- | --- |
| Aadhaar | valid, blurred, incomplete, profile_mismatch |
| PAN | valid, blurred, incomplete, profile_mismatch |
| Income Certificate | valid, blurred, incomplete, profile_mismatch, expired |

The fixture generator is `scripts/generate_synthetic_documents.py`.

Do not replace these files with real or realistic identity documents.
