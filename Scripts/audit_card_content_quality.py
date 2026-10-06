#!/usr/bin/env python3
"""Kart içerikleri için MVP kalite taraması."""
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
RESOURCES = REPO / "Scarlight/Resources"
CARD_FILES = ("deck_packs.json", "prop_questions.json", "bar_social_packs.json")
LIGHTER_FILES = ("lighter_questions.json",)

PLACEHOLDER_PATTERN = re.compile(r"\{([^{}]+)\}")
WHITESPACE = re.compile(r"\s+")
QUESTION_TIME_LANGUAGE = re.compile(
    r"\d+\s*(?:saniye|sn|dakika|dk)|\bsüre(?:si|yi|yle|de|den)?\b|süre tut",
    re.IGNORECASE,
)
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


def normalized(text: str) -> str:
    return WHITESPACE.sub(" ", text.strip().lower())


def references_third_player(text: str) -> bool:
    return "{diğer oyuncu" in text or "{ÜO" in text or "{UO" in text


def is_three_player_only(card: dict) -> bool:
    return card.get("minPlayers", 2) == 3 and card.get("maxPlayers", 99) == 3


def scan() -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    text_index: dict[str, list[str]] = defaultdict(list)

    for filename in CARD_FILES:
        path = RESOURCES / filename
        if not path.exists():
            warnings.append(f"{filename}: dosya yok")
            continue

        cards = json.loads(path.read_text(encoding="utf-8"))
        for card in cards:
            card_id = card.get("id", "?")
            fields = {
                "text": card.get("text") or "",
                "onYesTask": card.get("onYesTask") or "",
            }

            for field, text in fields.items():
                if not text:
                    continue

                key = normalized(text)
                text_index[key].append(f"{filename}:{card_id}:{field}")

                if len(text) > 180:
                    warnings.append(f"{filename}:{card_id}:{field}: çok uzun metin ({len(text)} karakter)")

                for token in PLACEHOLDER_PATTERN.findall(text):
                    if token not in ALLOWED_PLACEHOLDERS:
                        errors.append(f"{filename}:{card_id}:{field}: bilinmeyen placeholder {{{token}}}")

                if (
                    field == "text"
                    and card.get("type") in ("question", "surpriseQuestion")
                    and QUESTION_TIME_LANGUAGE.search(text)
                ):
                    errors.append(f"{filename}:{card_id}:{field}: cevaplık soruda süre dili kaldı")

            combined = " ".join(fields.values())
            if references_third_player(combined) and not is_three_player_only(card):
                errors.append(f"{filename}:{card_id}: 3. oyuncu token'ı var ama kart 3 kişiye özel değil")

    for filename in LIGHTER_FILES:
        path = RESOURCES / filename
        if not path.exists():
            warnings.append(f"{filename}: dosya yok")
            continue

        questions = json.loads(path.read_text(encoding="utf-8"))
        for index, text in enumerate(questions, start=1):
            location = f"{filename}:#{index}"
            if not isinstance(text, str) or not text.strip():
                errors.append(f"{location}: boş veya geçersiz soru")
                continue

            key = normalized(text)
            text_index[key].append(location)

            if len(text) > 160:
                warnings.append(f"{location}: çok uzun metin ({len(text)} karakter)")

            if QUESTION_TIME_LANGUAGE.search(text):
                errors.append(f"{location}: çakmak sorusunda süre dili kaldı")

    duplicate_groups = [
        locations
        for locations in text_index.values()
        if len(locations) > 1
    ]
    for locations in duplicate_groups[:30]:
        warnings.append("duplicate: " + ", ".join(locations))
    if len(duplicate_groups) > 30:
        warnings.append(f"duplicate: {len(duplicate_groups) - 30} ek grup daha var")

    return errors, warnings


def main() -> None:
    errors, warnings = scan()

    print(f"İçerik kalite taraması: {len(errors)} hata, {len(warnings)} uyarı")
    for error in errors[:60]:
        print("HATA:", error)
    if len(errors) > 60:
        print(f"HATA: {len(errors) - 60} ek hata daha var")

    for warning in warnings[:80]:
        print("UYARI:", warning)
    if len(warnings) > 80:
        print(f"UYARI: {len(warnings) - 80} ek uyarı daha var")

    if errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
