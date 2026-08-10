import re
from pathlib import Path
import pytest

ROOT = Path(__file__).resolve().parents[1]


def test_no_hardcoded_secrets_or_real_pii():
    aadhaar_pattern = re.compile(r"(?<![A-Za-z0-9])\d{4}[ -]?\d{4}[ -]?\d{4}(?![A-Za-z0-9])")
    pan_pattern = re.compile(r"\b[A-Z]{5}[0-9]{4}[A-Z]\b")
    secret_patterns = [
        re.compile(r"-----BEGIN (?:RSA |EC )?PRIVATE KEY-----"),
        re.compile(r"\bAIza[0-9A-Za-z_-]{30,}\b"),
        re.compile(r"\beyJ[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]{20,}\b"),
    ]

    allowed_extensions = {".json", ".csv", ".md", ".py", ".txt", ".example", ".gitignore", ".yaml", ".yml", ".dart"}
    violations = []

    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        if any(part in path.parts for part in (".git", ".venv", "build", ".dart_tool", "node_modules")):
            continue
        if path.suffix not in allowed_extensions and path.name != ".gitignore":
            continue

        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue

        if aadhaar_pattern.search(text):
            violations.append(f"Aadhaar pattern found in {path.relative_to(ROOT)}")
        if pan_pattern.search(text):
            violations.append(f"PAN pattern found in {path.relative_to(ROOT)}")

        if path.name != ".env.example":
            for pattern in secret_patterns:
                if pattern.search(text):
                    violations.append(f"Possible real secret found in {path.relative_to(ROOT)}")

    assert not violations, "Security violations detected:\n" + "\n".join(violations)
