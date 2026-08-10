"""Generate deterministic synthetic OCR fixtures for Schemora Phase 0."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFilter, ImageFont, PngImagePlugin


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_ROOT = ROOT / "data" / "synthetic_documents"
WATERMARK = "SAMPLE - NOT VALID"
FIXTURE_DATE = "2026-08-07"


def load_font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    candidates = [
        Path("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf"),
        Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size=size)
    return ImageFont.load_default()


FONT_TITLE = load_font(34, bold=True)
FONT_LABEL = load_font(24, bold=True)
FONT_BODY = load_font(25)
FONT_SMALL = load_font(20)
FONT_WATERMARK = load_font(42, bold=True)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def draw_watermark(image: Image.Image) -> None:
    draw = ImageDraw.Draw(image)
    bbox = draw.textbbox((0, 0), WATERMARK, font=FONT_WATERMARK)
    width = bbox[2] - bbox[0]
    x = max(24, (image.width - width) // 2)
    y = image.height - 82
    draw.rectangle((x - 18, y - 10, x + width + 18, y + 56), fill=(255, 245, 245))
    draw.text((x, y), WATERMARK, fill=(185, 20, 20), font=FONT_WATERMARK)


def draw_field(draw: ImageDraw.ImageDraw, y: int, label: str, value: str | None) -> int:
    draw.text((70, y), label, fill=(30, 40, 55), font=FONT_LABEL)
    shown = value if value is not None else "[FIELD INTENTIONALLY MISSING]"
    draw.text((390, y), shown, fill=(45, 55, 70), font=FONT_BODY)
    return y + 58


def base_document(
    title: str,
    subtitle: str,
    size: tuple[int, int],
    header_color: tuple[int, int, int],
) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGB", size, (248, 249, 251))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((28, 28, size[0] - 28, size[1] - 28), radius=18, fill=(255, 255, 255), outline=(135, 145, 160), width=3)
    draw.rounded_rectangle((29, 29, size[0] - 29, 150), radius=17, fill=header_color)
    draw.text((65, 56), title, fill=(255, 255, 255), font=FONT_TITLE)
    draw.text((67, 108), subtitle, fill=(240, 245, 250), font=FONT_SMALL)
    draw.text((size[0] - 360, 165), "NOT A GOVERNMENT DOCUMENT", fill=(175, 25, 25), font=FONT_SMALL)
    return image, draw


def finalize_image(
    image: Image.Image,
    output_path: Path,
    *,
    blur: bool = False,
) -> None:
    if blur:
        image = image.filter(ImageFilter.GaussianBlur(radius=5))
    draw_watermark(image)
    metadata = PngImagePlugin.PngInfo()
    metadata.add_text("watermark", WATERMARK)
    metadata.add_text("synthetic", "true")
    metadata.add_text("generated_for", "Schemora Phase 0 OCR benchmark")
    image.save(output_path, "PNG", pnginfo=metadata, optimize=True)


def write_sidecar(
    output_path: Path,
    *,
    fixture_id: str,
    document_type: str,
    variant: str,
    readability: str,
    completeness: str,
    consistency: str,
    expected_fields: dict[str, Any],
) -> None:
    sidecar = {
        "fixture_id": fixture_id,
        "document_type": document_type,
        "variant": variant,
        "synthetic": True,
        "watermark_text": WATERMARK,
        "image_file": output_path.name,
        "image_sha256": sha256_file(output_path),
        "expected_readability": readability,
        "expected_completeness": completeness,
        "expected_profile_consistency": consistency,
        "expected_fields": expected_fields,
    }
    output_path.with_suffix(".json").write_text(
        json.dumps(sidecar, indent=2) + "\n",
        encoding="utf-8",
    )


def generate_aadhaar(variant: str) -> None:
    folder = OUTPUT_ROOT / "aadhaar"
    folder.mkdir(parents=True, exist_ok=True)
    image, draw = base_document(
        "SYNTHETIC AADHAAR OCR FIXTURE",
        "Fictional identity data for automated testing only",
        (1200, 760),
        (44, 106, 126),
    )

    fields: dict[str, str | None] = {
        "name": "Aarav Kulkarni",
        "date_of_birth": "14/11/2005",
        "gender": "Male",
        "address": "42 Sample Lane, Pune, Maharashtra 411001",
        "masked_aadhaar": "XXXX XXXX 4821",
    }
    if variant == "incomplete":
        fields["address"] = None
        fields["masked_aadhaar"] = None
    elif variant == "profile_mismatch":
        fields["name"] = "Riya Sen"
        fields["date_of_birth"] = "09/04/2004"
        fields["gender"] = "Female"

    y = 225
    for label, key in [
        ("Name", "name"),
        ("Date of Birth", "date_of_birth"),
        ("Gender", "gender"),
        ("Address", "address"),
        ("Masked Number", "masked_aadhaar"),
    ]:
        y = draw_field(draw, y, label, fields[key])

    output = folder / f"aadhaar_{variant}.png"
    is_blurred = variant == "blurred"
    finalize_image(image, output, blur=is_blurred)
    expected = {key: (None if is_blurred else value) for key, value in fields.items()}
    write_sidecar(
        output,
        fixture_id=f"fixture-aadhaar-{variant.replace('_', '-')}",
        document_type="Aadhaar",
        variant=variant,
        readability="Unreadable" if is_blurred else "Readable",
        completeness="Incomplete" if variant == "incomplete" else "Complete",
        consistency="Mismatch" if variant == "profile_mismatch" else ("NotEvaluated" if is_blurred or variant == "incomplete" else "Consistent"),
        expected_fields=expected,
    )


def generate_pan(variant: str) -> None:
    folder = OUTPUT_ROOT / "pan"
    folder.mkdir(parents=True, exist_ok=True)
    image, draw = base_document(
        "SYNTHETIC PAN OCR FIXTURE",
        "Fictional tax-identifier layout for automated testing only",
        (1200, 720),
        (43, 74, 125),
    )

    fields: dict[str, str | None] = {
        "name": "Aarav Kulkarni",
        "date_of_birth": "14/11/2005",
        "masked_pan": "ABCDE****F",
    }
    if variant == "incomplete":
        fields["date_of_birth"] = None
        fields["masked_pan"] = None
    elif variant == "profile_mismatch":
        fields["name"] = "Riya Sen"
        fields["date_of_birth"] = "09/04/2004"

    y = 245
    for label, key in [
        ("Name", "name"),
        ("Date of Birth", "date_of_birth"),
        ("Masked PAN", "masked_pan"),
    ]:
        y = draw_field(draw, y, label, fields[key])

    output = folder / f"pan_{variant}.png"
    is_blurred = variant == "blurred"
    finalize_image(image, output, blur=is_blurred)
    expected = {key: (None if is_blurred else value) for key, value in fields.items()}
    write_sidecar(
        output,
        fixture_id=f"fixture-pan-{variant.replace('_', '-')}",
        document_type="PAN",
        variant=variant,
        readability="Unreadable" if is_blurred else "Readable",
        completeness="Incomplete" if variant == "incomplete" else "Complete",
        consistency="Mismatch" if variant == "profile_mismatch" else ("NotEvaluated" if is_blurred or variant == "incomplete" else "Consistent"),
        expected_fields=expected,
    )


def generate_income_certificate(variant: str) -> None:
    folder = OUTPUT_ROOT / "income_certificate"
    folder.mkdir(parents=True, exist_ok=True)
    image, draw = base_document(
        "SYNTHETIC INCOME CERTIFICATE FIXTURE",
        "Fictional certificate data for automated testing only",
        (1200, 980),
        (58, 112, 75),
    )

    fields: dict[str, str | int | None] = {
        "applicant_name": "Aarav Kulkarni",
        "annual_income": 180000,
        "issuing_authority": "Sample Revenue Office, Pune",
        "issue_date": "2026-04-01",
        "validity_date": "2027-03-31",
    }
    if variant == "incomplete":
        fields["issuing_authority"] = None
        fields["validity_date"] = None
    elif variant == "profile_mismatch":
        fields["applicant_name"] = "Riya Sen"
        fields["annual_income"] = 450000
    elif variant == "expired":
        fields["issue_date"] = "2024-04-01"
        fields["validity_date"] = "2025-03-31"

    y = 235
    for label, key in [
        ("Applicant Name", "applicant_name"),
        ("Annual Income", "annual_income"),
        ("Issuing Authority", "issuing_authority"),
        ("Issue Date", "issue_date"),
        ("Validity Date", "validity_date"),
    ]:
        value = fields[key]
        shown = f"INR {value}" if key == "annual_income" and value is not None else (str(value) if value is not None else None)
        y = draw_field(draw, y, label, shown)

    draw.text(
        (70, 600),
        f"Fixture reference date: {FIXTURE_DATE}",
        fill=(75, 85, 95),
        font=FONT_SMALL,
    )
    draw.text(
        (70, 645),
        "This file has no legal validity and must never be used as evidence.",
        fill=(160, 30, 30),
        font=FONT_LABEL,
    )

    output = folder / f"income_certificate_{variant}.png"
    is_blurred = variant == "blurred"
    finalize_image(image, output, blur=is_blurred)
    expected = {key: (None if is_blurred else value) for key, value in fields.items()}
    write_sidecar(
        output,
        fixture_id=f"fixture-income-certificate-{variant.replace('_', '-')}",
        document_type="IncomeCertificate",
        variant=variant,
        readability="Unreadable" if is_blurred else "Readable",
        completeness="Incomplete" if variant == "incomplete" else "Complete",
        consistency="Mismatch" if variant == "profile_mismatch" else ("NotEvaluated" if is_blurred or variant == "incomplete" else "Consistent"),
        expected_fields=expected,
    )


def main() -> None:
    for variant in ("valid", "blurred", "incomplete", "profile_mismatch"):
        generate_aadhaar(variant)
        generate_pan(variant)
    for variant in ("valid", "blurred", "incomplete", "profile_mismatch", "expired"):
        generate_income_certificate(variant)
    print("Generated 13 synthetic OCR fixtures with sidecar JSON files.")


if __name__ == "__main__":
    main()
