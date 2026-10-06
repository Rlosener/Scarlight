#!/usr/bin/env python3
"""Tüm deste JSON dosyalarını normalize eder."""
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
RESOURCES = REPO / "Scarlight/Resources"

sys.path.insert(0, str(REPO / "Scripts"))
from card_content_utils import normalize_card  # noqa: E402


def process_file(path: Path) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    changed_count = 0
    for i, card in enumerate(data):
        updated, changed = normalize_card(card)
        data[i] = updated
        if changed:
            changed_count += 1
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"{path.name}: {changed_count}/{len(data)} kart güncellendi")


def main() -> None:
    for name in ("deck_packs.json", "prop_questions.json"):
        path = RESOURCES / name
        if path.exists():
            process_file(path)
        else:
            print(f"SKIP {path}")


if __name__ == "__main__":
    main()
