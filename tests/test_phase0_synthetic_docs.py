import hashlib
import json
from pathlib import Path
import pytest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SYNTHETIC_DIR = ROOT / "data" / "synthetic_documents"
WATERMARK = "SAMPLE - NOT VALID"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def test_synthetic_document_variant_counts():
    expected = {
        "aadhaar": {"valid", "blurred", "incomplete", "profile_mismatch"},
        "pan": {"valid", "blurred", "incomplete", "profile_mismatch"},
        "income_certificate": {"valid", "blurred", "incomplete", "profile_mismatch", "expired"},
    }
    for doc_type, expected_variants in expected.items():
        folder = SYNTHETIC_DIR / doc_type
        assert folder.exists(), f"Synthetic document folder missing: {doc_type}"
        pngs = {p.stem.split(f"{doc_type}_", 1)[-1] for p in folder.glob("*.png")}
        assert pngs == expected_variants, f"Doc type {doc_type} variants mismatch: expected {expected_variants}, got {pngs}"


def test_synthetic_document_hashes_and_metadata():
    png_files = list(SYNTHETIC_DIR.rglob("*.png"))
    assert len(png_files) == 13, f"Expected 13 synthetic document images, found {len(png_files)}"

    for image_path in png_files:
        sidecar_path = image_path.with_suffix(".json")
        assert sidecar_path.exists(), f"Missing sidecar JSON for image: {image_path}"

        sidecar = json.loads(sidecar_path.read_text(encoding="utf-8"))
        actual_hash = sha256_file(image_path)
        assert sidecar["image_sha256"] == actual_hash, f"SHA-256 mismatch for {image_path.name}"

        with Image.open(image_path) as img:
            assert img.width >= 1000 and img.height >= 600, f"Image {image_path.name} resolution too small: {img.width}x{img.height}"
            assert img.info.get("watermark") == WATERMARK, f"Image {image_path.name} missing watermark metadata"
