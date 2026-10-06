#!/usr/bin/env python3
"""Kart JSON dosyalarını doğrular; sorun varsa exit 1."""
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
RESOURCES = REPO / "Scarlight/Resources"

sys.path.insert(0, str(REPO / "Scripts"))
from card_content_utils import migrate_legacy_tokens  # noqa: E402

CARD_FILES = ("deck_packs.json", "prop_questions.json", "bar_social_packs.json")
LIGHTER_FILES = ("lighter_questions.json",)
DURATION_IN_TEXT = re.compile(
    r"\d+\s*(?:saniye|sn|dakika|dk)|\bbir\s+dakika\b|\bsüre(?:si|yi|yle|de|den)?\b|süre tut",
    re.I,
)
PLACEHOLDER_PATTERN = re.compile(r"\{([^{}]+)\}")
ALLOWED_PLACEHOLDERS = {
    "partner",
    "partnere",
    "partneri",
    "partnerin",
    "partnerle",
    "diğer oyuncu",
    "diğer oyuncuya",
    "diğer oyuncuyu",
    "diğer oyuncunun",
    "diğer oyuncuyla",
    "sıradaki",
    "item",
    "eşya",
    "duration",
    "phase",
}


def validate_placeholders(path: Path, cid: str, field: str, text: str, errors: list[str]) -> None:
    normalized_text = migrate_legacy_tokens(text)
    for token in PLACEHOLDER_PATTERN.findall(normalized_text):
        if token not in ALLOWED_PLACEHOLDERS:
            errors.append(f"{path.name}:{cid}:{field} bilinmeyen placeholder {{{token}}}")


def validate_file(path: Path) -> list[str]:
    errors: list[str] = []
    data = json.loads(path.read_text(encoding="utf-8"))
    for card in data:
        cid = card.get("id", "?")
        for field in ("text", "onYesTask"):
            text = card.get(field) or ""
            if not text:
                continue
            validate_placeholders(path, cid, field, text, errors)
            if (
                field == "text"
                and card.get("type") in ("question", "surpriseQuestion")
                and DURATION_IN_TEXT.search(text)
            ):
                errors.append(f"{path.name}:{cid}:{field} soru metninde süre dili")
        if not card.get("durationSeconds"):
            errors.append(f"{path.name}:{cid} durationSeconds eksik")
        if not card.get("text", "").strip():
            errors.append(f"{path.name}:{cid} boş text")
    return errors


def validate_lighter_file(path: Path) -> list[str]:
    errors: list[str] = []
    data = json.loads(path.read_text(encoding="utf-8"))
    for index, text in enumerate(data, start=1):
        if not isinstance(text, str) or not text.strip():
            errors.append(f"{path.name}:#{index} boş veya geçersiz soru")
            continue
        if DURATION_IN_TEXT.search(text):
            errors.append(f"{path.name}:#{index} çakmak sorusunda süre dili")
    return errors


def main() -> None:
    all_errors: list[str] = []
    for name in CARD_FILES:
        path = RESOURCES / name
        if path.exists():
            all_errors.extend(validate_file(path))
    for name in LIGHTER_FILES:
        path = RESOURCES / name
        if path.exists():
            all_errors.extend(validate_lighter_file(path))

    if all_errors:
        print(f"HATA: {len(all_errors)} sorun")
        for err in all_errors[:30]:
            print(" -", err)
        if len(all_errors) > 30:
            print(f" ... ve {len(all_errors) - 30} tane daha")
        sys.exit(1)

    print("Tüm kart içerikleri geçerli.")


if __name__ == "__main__":
    main()
