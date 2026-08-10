# Schemora Phase 0.1 Plan

Status: Planning only

Phase 0.1 will research, review, and add the remaining 22 scheme records after Phase 0 is approved.

No Phase 0.1 scheme records, AI ingestion, embeddings, or RAG implementation are included in the current phase.

## Inventory Roadmap

The existing inventory reserves the following research capacity:

| Jurisdiction | Planned Slots | Focus |
| --- | ---: | --- |
| Central | 6 | Scholarship, education, skill development, employment, entrepreneurship, financial assistance |
| Maharashtra | 2 | Scholarship and skill development |
| Gujarat | 2 | Scholarship and entrepreneurship |
| Karnataka | 2 | Scholarship and skill development |
| Tamil Nadu | 2 | Scholarship and employment |
| Rajasthan | 2 | Scholarship and social welfare |
| Madhya Pradesh | 2 | Scholarship and skill development |
| Uttar Pradesh | 2 | Scholarship and employment |
| Delhi | 2 | Scholarship and entrepreneurship |

The final names will not be selected from memory. Every planned slot begins with official-source discovery.

## Source Verification Workflow

For each planned slot:

1. Identify the responsible government department.
2. Locate the latest government notification or guideline.
3. Locate the official scheme information page.
4. Locate the official application portal.
5. Record publication, effective, retrieval, and verification dates.
6. Capture or download a stable source snapshot when permitted.
7. Calculate a SHA-256 content hash.
8. Compare all official sources for conflicts.
9. Mark unresolved or dynamic fields `VerificationRequired`.
10. Reject blogs, aggregators, social posts, and unsupported summaries.

Source authority order:

1. Latest government notification
2. Official department or scheme portal
3. Official guideline
4. Official application portal
5. Official FAQ

## Review Checklist

Two reviewers should verify:

- Exact official scheme name
- Owning department
- Jurisdiction and state
- Current scheme status
- Benefit amounts and frequency
- Every mandatory and advisory rule
- Rule operators and profile-field mappings
- Required documents
- Application steps
- Application windows
- Official information and application URLs
- Source dates and hashes
- Verification-required fields
- No definitive government-approval claim

A scheme moves to `Implemented` only when:

- Source status is `Verified` or its limitations are explicitly approved.
- Rule status is `Validated`.
- Checklist status is `Validated`.
- Benchmark results exist.
- The Phase 0 validator passes.

## Versioning Strategy

- Keep dataset filenames at `v1` while adding backward-compatible records.
- Increment to `v2` only for breaking schema or enum changes.
- Use `YYYY-MM-DD-vN` for independent scheme versions.
- Create a new scheme version when eligibility, benefits, documents, deadlines, or application channels change materially.
- Retain superseded source records with `source_status: Superseded`.
- Recalculate the frozen dataset manifest after every approved dataset change.
- Tag reviewed dataset releases in Git.

## Benchmark Expansion

For every new scheme:

1. Add at least three positive or near-positive profiles.
2. Add at least three clear mandatory-rule failures.
3. Add at least two missing-information cases.
4. Cover nested AND/OR behavior when present.
5. Add document-checklist expectations.
6. Link every expected result to supporting source IDs.
7. Run deterministic evaluation and manual review.

Top 3 recommendation benchmarks should begin only after at least five fully validated schemes compete for the same profile. Ranking expectations must be reviewed separately from eligibility expectations.

## RAG Dataset Expansion Planning

RAG implementation remains outside Phase 0.1. The dataset will prepare for later ingestion by:

- Preserving source IDs and scheme IDs
- Keeping source language and authority metadata
- Recording page numbers for future PDF extraction when available
- Separating current and superseded sources
- Marking publication status explicitly
- Keeping unresolved facts out of approved source-backed answers

When RAG implementation begins in a later phase:

1. Extract text from approved sources.
2. Review extraction before publication.
3. Chunk by scheme section and source.
4. Attach scheme, source, version, page, and verification metadata.
5. Generate embeddings only for approved chunks.
6. Exclude superseded and unresolved content from citizen retrieval.
7. Validate citations against retrieved source IDs.

## Phase 0.1 Completion Gate

Phase 0.1 is complete when:

- All 25 inventory rows have exact verified scheme names.
- All 25 schemes have structured records and sources.
- Every scheme has benchmark eligibility and checklist cases.
- Ranking benchmarks are added where meaningful.
- No planned research placeholders remain.
- The validator and frozen manifest pass.
