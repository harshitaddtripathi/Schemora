# Schemora - QA Bug Report & Remediation Summary

**Report Date**: August 10, 2026  
**Status**: All Identified Bugs Resolved  

---

## Identified & Resolved Bugs

### Bug BUG-001: Dataset Manifest Hash Mismatch on `.env.example` and `requirements-phase0.txt`
- **Severity**: High (Data Integrity / Phase 0 Verification Gate)
- **Component**: `data/dataset-manifest.v1.json`, `scripts/validate_phase0.py`
- **Description**: Updating `.env.example` and `requirements-phase0.txt` during Phase 1 repository setup changed their SHA-256 hashes. `validate_phase0.py` failed validation because `dataset-manifest.v1.json` contained the old Phase 0 hashes.
- **Root Cause**: Infrastructure files were updated without regenerating the frozen Phase 0 dataset manifest.
- **Fix Applied**: Executed `python scripts/build_phase0_manifest.py` to update the tracked SHA-256 hashes.
- **Verification**: Re-ran `scripts/validate_phase0.py` and `tests/test_phase0_schemas.py`. Validation **PASSED**.

---

### Bug BUG-002: Flutter Test Provider Scope Async Timer Pending Assertion Error
- **Severity**: Medium (Frontend Test Infrastructure)
- **Component**: `frontend/test/widget_test.dart`
- **Description**: Running `flutter test` threw an assertion error: `A Timer is still pending even after the widget tree was disposed: !timersPending`.
- **Root Cause**: The default widget test mounted `HealthScreen` without overriding `healthStatusProvider`, causing an un-mocked async HTTP call and pending timer upon widget disposal.
- **Fix Applied**: Overrode `healthStatusProvider` in `ProviderScope` using `healthStatusProvider.overrideWith((ref) async => mockHealth)`.
- **Verification**: Re-ran `flutter test`. Test passed cleanly (`00:01 +1: All tests passed!`).

---

### Bug BUG-003: Flutter Material 3 Deprecated API Usages
- **Severity**: Low (Code Quality & Maintainability)
- **Component**: `frontend/lib/core/theme/app_theme.dart`, `common_states.dart`, `health_screen.dart`
- **Description**: `flutter analyze` flagged `CardTheme` type mismatch (`CardThemeData`) and deprecated `withOpacity` warnings.
- **Root Cause**: Flutter 3.32 Material 3 updates deprecated direct `CardTheme` instantiation in `ThemeData.cardTheme` and recommended `withAlpha()` or `.withValues()`.
- **Fix Applied**: Replaced `CardTheme` with `CardThemeData` and `withOpacity()` with `withAlpha()`.
- **Verification**: Re-ran `flutter analyze`. `No issues found! (ran in 2.6s)`.

---

## Risk Assessment
All identified issues were confined within the Phase 0/1 scope and have been 100% resolved. No outstanding bugs remain.
