# Official Source Register

`source-register.csv` contains only official government sources used by implemented pilot schemes.

## Source Status

- `Verified`: official source was retrieved and its content hash was recorded.
- `VerificationRequired`: the source is official, but a stable snapshot, current detail, or reachability check remains outstanding.
- `Superseded`: retained for history but not valid for current decisions.
- `Collected`: retrieved but not yet reviewed.
- `PendingResearch`: planned but not collected.

## Hash Policy

`source_hash` is the SHA-256 hash of retrieved UTF-8 page content when a stable retrieval succeeded.

Dynamic pages that could not be snapshotted use `verification_required`. This value prevents the dataset from pretending that an unarchived source was fully verified.

## Source Priority

1. Latest government notification
2. Official scheme or department page
3. Official application portal
4. Official guideline
5. Official FAQ

Conflicting sources must be reviewed before a scheme version is updated.
